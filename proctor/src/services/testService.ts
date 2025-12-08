import axios from 'axios'

const baseURL = (import.meta.env.VITE_API_URL as string) ?? '/api'
const api = axios.create({ baseURL })

export interface Test {
  id: number
  title: string
  testAccountPrefix?: string
  startTime?: string | null
}

export interface CreateTestPayload {
  title: string
  testAccountPrefix?: string
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

