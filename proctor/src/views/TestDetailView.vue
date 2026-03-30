<script setup lang="ts">
import { useApolloClientStore } from '@/stores/ApolloClientStore'
import { gql } from '@apollo/client'
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'

const { client } = useApolloClientStore()
const route = useRoute()
const router = useRouter()

const testId = route.params.id as string

interface Test {
  id: string
  title: string
  pin: number
  teacherId: string
  startTime: string | null
  endTime: string | null
}

const testData = ref<Test | null>(null)

function fetchTest() {
  client
    .query<{ testId: Test }>({
      query: gql`
        query GetTest($id: String!) {
          testId(id: $id) {
            id
            title
            pin
            teacherId
            startTime
            endTime
          }
        }
      `,
      variables: { id: testId },
      fetchPolicy: 'network-only'
    })
    .then((res) => {
      if (res.data?.testId) {
        testData.value = res.data.testId
      }
    })
    .catch((e) => {
      console.error('Failed to fetch test!', e)
    })
}

onMounted(() => {
  fetchTest()
})

async function goBack() {
  await router.push('/tests')
}

function startTest() {
  if (!testData.value) return

  const currentTitle = testData.value.title

  client.mutate<{ updateTest: Test }>({
    mutation: gql`
      mutation StartTest($id: String!, $test: TestInput!) {
        updateTest(id: $id, test: $test) {
          id
          startTime
          endTime
        }
      }
    `,
    variables: {
      id: testId,
      test: {
        title: currentTitle,
        startTime: new Date().toISOString()
      }
    }
  }).then((res) => {
    if (res.data?.updateTest) {
      fetchTest()
    }
  }).catch(e => {
    console.error("Failed to start test", e)
  })
}

function endTest() {
  if (!testData.value) return

  const currentTitle = testData.value.title
  const currentStartTime = testData.value.startTime

  client.mutate<{ updateTest: Test }>({
    mutation: gql`
      mutation EndTest($id: String!, $test: TestInput!) {
        updateTest(id: $id, test: $test) {
          id
          startTime
          endTime
        }
      }
    `,
    variables: {
      id: testId,
      test: {
        title: currentTitle,
        startTime: currentStartTime,
        endTime: new Date().toISOString()
      }
    }
  }).then((res) => {
    if (res.data?.updateTest) {
      fetchTest()
    }
  }).catch(e => {
    console.error("Failed to end test", e)
  })
}

</script>

<template>
  <div class="view-management" v-if="testData">
    <header class="top-bar">
      <div class="header-controls">
        <button class="back-btn" @click="goBack">
          Back to Tests
        </button>
      </div>
      <div class="status-indicator" v-if="testData.startTime && !testData.endTime">
        <span class="live-dot"></span>
        <span>Monitoring</span>
      </div>
    </header>

    <div class="session-info-grid">
      <div class="info-card">
        <div class="info-label">Exam Title</div>
        <div class="info-value">{{ testData.title || 'Untitled Test' }}</div>
      </div>
      <div class="info-card">
        <div class="info-label">Access PIN</div>
        <div class="info-value">
          <span>{{ testData.pin || '---' }}</span>
        </div>
        <div class="info-sub">Provide to students</div>
      </div>
      <div class="info-card">
        <div class="info-label">Status</div>
        <div class="info-value">
          <span v-if="testData.endTime">Completed</span>
          <span v-else-if="testData.startTime">Live</span>
          <span v-else>Preparation</span>
        </div>
      </div>
      <div class="info-card actions-card">
        <div class="info-label">Actions</div>
        <div class="action-buttons">
          <button class="btn-primary" v-if="!testData.startTime" @click="startTest">Start Test</button>
          <button class="btn-secondary" v-if="testData.startTime && !testData.endTime" @click="endTest">End Test</button>
          <span v-if="testData.endTime" class="info-sub">Test is completed</span>
        </div>
      </div>
    </div>
  </div>
  <div v-else class="view-management loading-state">
    <p>Loading test details...</p>
  </div>
</template>

<style scoped>
.view-management {
  padding: 40px;
  max-width: 1200px;
  margin: 0 auto;
}

.top-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 30px;
}

.back-btn {
  border: none;
  background: var(--bg-card);
  color: var(--text-primary);
  padding: 10px 18px;
  border-radius: 10px;
  cursor: pointer;
  font-weight: 600;
  display: flex;
  align-items: center;
  gap: 8px;
  border: 1px solid var(--border-default);
  transition: all 0.2s;
}
.back-btn:hover {
  background: var(--bg-input);
  border-color: var(--border-strong);
}

.status-indicator {
  font-size: 0.85rem;
  font-weight: 700;
  color: var(--text-primary);
  display: flex;
  align-items: center;
  gap: 8px;
}
.live-dot {
  width: 10px;
  height: 10px;
  background: var(--alert-warning-bg);
  border: 1px solid var(--warning);
  border-radius: 50%;
  animation: pulse 2s infinite;
}
@keyframes pulse {
  0% { box-shadow: 0 0 0 0 rgba(239, 113, 159, 0.7); }
  70% { box-shadow: 0 0 0 10px rgba(239, 113, 159, 0); }
  100% { box-shadow: 0 0 0 0 rgba(239, 113, 159, 0); }
}

.session-info-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 15px;
  margin-bottom: 25px;
}
.info-card {
  background: var(--bg-card);
  padding: 18px;
  border-radius: 18px;
  border: 1px solid var(--border-default);
}
.info-label {
  font-size: 0.7rem;
  color: var(--text-secondary);
  font-weight: 700;
  text-transform: uppercase;
  margin-bottom: 8px;
}
.info-value {
  font-size: 1.2rem;
  font-weight: 700;
  color: var(--text-primary);
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.info-sub {
  font-size: 0.75rem;
  color: var(--text-secondary);
  margin-top: 4px;
}
.actions-card {
  display: flex;
  flex-direction: column;
}
.action-buttons {
  margin-top: auto;
}

.btn-primary {
  background: var(--primary);
  color: white;
  border: none;
  padding: 10px 20px;
  border-radius: 10px;
  font-weight: 600;
  cursor: pointer;
  width: 100%;
}
.btn-primary:hover {
  opacity: 0.9;
}
.btn-secondary {
  background: var(--bg-body);
  border: 1px solid var(--border-default);
  padding: 10px 20px;
  border-radius: 10px;
  font-weight: 600;
  cursor: pointer;
  width: 100%;
  color: var(--text-primary);
}
.btn-secondary:hover {
  background: var(--border-default);
}

.loading-state {
  text-align: center;
  color: var(--text-secondary);
  font-size: 1.2rem;
  margin-top: 50px;
}
</style>
