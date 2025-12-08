import axios from 'axios'

const baseURL = (import.meta.env.VITE_API_URL as string) ?? '/api'
const api = axios.create({ baseURL })

export interface Test {
  id: number
  title: string
  testAccountPrefix?: string
  // List endpoint returns start/end, single get returns startTime/endTime
  start?: string | null
  end?: string | null
  startTime?: string | null
  endTime?: string | null
}

export interface CreateTestPayload {
  title: string
  testAccountPrefix?: string
}

export interface PatchTestPayload {
  id: number
  title?: string
  testAccountPrefix?: string
  startTime?: string | null
  endTime?: string | null
}

export async function listTests(): Promise<Test[]> {
  const res = await api.get<Test[]>('/test')
  return res.data
}

export async function createTest(payload: CreateTestPayload): Promise<Test> {
  const res = await api.post<Test>('/test', payload)
  return res.data
}

export async function deleteTest(id: number): Promise<void> {
  await api.delete(`/test/${id}`)
}

export async function getTest(id: number): Promise<Test> {
  const res = await api.get<Test>(`/test/${id}`)
  return res.data
}

export async function patchTest(payload: PatchTestPayload): Promise<void> {
  await api.patch('/test', payload)
}

export async function startTest(id: number): Promise<Test> {
  await patchTest({ id, startTime: new Date().toISOString() })
  return getTest(id)
}

export async function stopTest(id: number): Promise<Test> {
  await patchTest({ id, endTime: new Date().toISOString() })
  return getTest(id)
}

