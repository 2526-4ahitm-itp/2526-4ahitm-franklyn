export interface PresenceMark {
  at: number
  exact: boolean
}

export interface SentinelJournalEntry {
  joined?: PresenceMark
  left?: PresenceMark
}

export type SentinelJournal = Record<string, SentinelJournalEntry>

export interface TimelineSession {
  sentinelId: string
  studentId: string
}

export interface TimelineInput {
  sessions: TimelineSession[]
  journal: SentinelJournal
  presenceKnown: boolean
  onlineIds: ReadonlySet<string>
  examStart: number | null
  examEnd: number | null
  fallbackTime: (key: string) => number
}

export interface TimelineEvent {
  id: string
  type: 'join' | 'leave'
  studentId: string
  time: number
  exact: boolean
}

export interface SessionTimes {
  joined: PresenceMark
  left: PresenceMark | null
}

export interface Timeline {
  events: TimelineEvent[]
  presentStudentIds: Set<string>
  sessionTimes: Map<string, SessionTimes>
  peakStudentCount: number
}

function betterMark(
  a: PresenceMark | undefined,
  b: PresenceMark | undefined,
): PresenceMark | undefined {
  if (!a) return b
  if (!b) return a
  if (a.exact !== b.exact) return a.exact ? a : b
  return a.at <= b.at ? a : b
}

export function mergeJournals(a: SentinelJournal, b: SentinelJournal): SentinelJournal {
  const merged: SentinelJournal = {}
  for (const id of new Set([...Object.keys(a), ...Object.keys(b)])) {
    const joined = betterMark(a[id]?.joined, b[id]?.joined)
    const left = betterMark(a[id]?.left, b[id]?.left)
    merged[id] = { ...(joined && { joined }), ...(left && { left }) }
  }
  return merged
}

export function applySnapshot(
  journal: SentinelJournal,
  previousIds: ReadonlySet<string>,
  nextIds: ReadonlySet<string>,
  now: number,
  live: boolean,
): SentinelJournal {
  const next: SentinelJournal = { ...journal }
  for (const id of nextIds) {
    const entry = next[id] ?? {}
    next[id] = {
      joined: entry.joined ?? { at: now, exact: live && !previousIds.has(id) },
    }
  }
  for (const id of previousIds) {
    if (nextIds.has(id)) continue
    const entry = next[id] ?? {}
    next[id] = {
      joined: entry.joined ?? { at: now, exact: false },
      left: entry.left ?? { at: now, exact: live },
    }
  }
  return next
}

export function pruneJournal(journal: SentinelJournal, cutoff: number): SentinelJournal {
  return Object.fromEntries(
    Object.entries(journal).filter(([, entry]) => {
      const latest = Math.max(entry.joined?.at ?? 0, entry.left?.at ?? 0)
      return latest >= cutoff
    }),
  )
}

export function isSessionPresent(
  sentinelId: string,
  input: Pick<TimelineInput, 'journal' | 'presenceKnown' | 'onlineIds' | 'examEnd'>,
): boolean {
  if (input.presenceKnown) return input.onlineIds.has(sentinelId)
  return !input.journal[sentinelId]?.left && input.examEnd === null
}

function resolveJoin(session: TimelineSession, input: TimelineInput): PresenceMark {
  const recorded = input.journal[session.sentinelId]?.joined
  if (recorded) return recorded
  if (input.examStart !== null) return { at: input.examStart, exact: false }
  return { at: input.fallbackTime(`${session.sentinelId}:join`), exact: false }
}

function resolveLeave(
  session: TimelineSession,
  joined: PresenceMark,
  nextJoin: number | null,
  input: TimelineInput,
): PresenceMark {
  const recorded = input.journal[session.sentinelId]?.left
  const candidates = [recorded?.at, nextJoin, input.examEnd].filter(
    (at): at is number => typeof at === 'number',
  )
  const estimate =
    candidates.length > 0
      ? Math.min(...candidates)
      : input.fallbackTime(`${session.sentinelId}:leave`)
  const mark = recorded?.exact ? recorded : { at: estimate, exact: false }
  return mark.at >= joined.at ? mark : { at: joined.at, exact: false }
}

function byTimeJoinsFirst(a: TimelineEvent, b: TimelineEvent): number {
  return a.time - b.time || (a.type === b.type ? 0 : a.type === 'join' ? -1 : 1)
}

export function buildTimeline(input: TimelineInput): Timeline {
  const sessionsByStudent = new Map<string, TimelineSession[]>()
  for (const session of input.sessions) {
    const list = sessionsByStudent.get(session.studentId) ?? []
    list.push(session)
    sessionsByStudent.set(session.studentId, list)
  }

  const events: TimelineEvent[] = []
  const presentStudentIds = new Set<string>()
  const sessionTimes = new Map<string, SessionTimes>()

  for (const [studentId, sessions] of sessionsByStudent) {
    const joins = new Map(sessions.map((s) => [s.sentinelId, resolveJoin(s, input)]))
    const ordered = [...sessions].sort(
      (a, b) =>
        (joins.get(a.sentinelId)?.at ?? 0) - (joins.get(b.sentinelId)?.at ?? 0) ||
        a.sentinelId.localeCompare(b.sentinelId),
    )

    const edges: TimelineEvent[] = []
    ordered.forEach((session, i) => {
      const joined = joins.get(session.sentinelId) ?? resolveJoin(session, input)
      edges.push({
        id: `${session.sentinelId}:join`,
        type: 'join',
        studentId,
        time: joined.at,
        exact: joined.exact,
      })

      if (isSessionPresent(session.sentinelId, input)) {
        sessionTimes.set(session.sentinelId, { joined, left: null })
        return
      }
      const next = ordered[i + 1]
      const nextJoin = next ? (joins.get(next.sentinelId)?.at ?? null) : null
      const left = resolveLeave(session, joined, nextJoin, input)
      sessionTimes.set(session.sentinelId, { joined, left })
      edges.push({
        id: `${session.sentinelId}:leave`,
        type: 'leave',
        studentId,
        time: left.at,
        exact: left.exact,
      })
    })

    let active = 0
    for (const edge of edges.sort(byTimeJoinsFirst)) {
      const before = active
      active += edge.type === 'join' ? 1 : -1
      if ((before === 0 && active > 0) || (before > 0 && active === 0)) {
        events.push(edge)
      }
    }
    if (active > 0) presentStudentIds.add(studentId)
  }

  events.sort((a, b) => byTimeJoinsFirst(b, a))

  let present = 0
  let peak = 0
  const ascending = [...events].reverse()
  ascending.forEach((event, i) => {
    present += event.type === 'join' ? 1 : -1
    const nextEvent = ascending[i + 1]
    if (!nextEvent || nextEvent.time !== event.time) peak = Math.max(peak, present)
  })

  return {
    events,
    presentStudentIds,
    sessionTimes,
    peakStudentCount: Math.max(peak, presentStudentIds.size),
  }
}
