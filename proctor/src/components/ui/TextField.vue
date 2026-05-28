<script setup lang="ts">
defineOptions({
  name: 'UiTextField',
  inheritAttrs: false,
})

interface Props {
  id: string
  label: string
  type?: 'text' | 'date' | 'time' | 'datetime-local' | 'email' | 'password' | 'number'
  multiline?: boolean
  modelValue?: string
}

withDefaults(defineProps<Props>(), {
  type: 'text',
  multiline: false,
  modelValue: '',
})

const emit = defineEmits<{
  (e: 'update:modelValue', value: string): void
}>()

function onInput(event: Event): void {
  emit('update:modelValue', (event.target as HTMLInputElement | HTMLTextAreaElement).value)
}
</script>

<template>
  <div class="field-group">
    <label :for="id" class="field-label">{{ label }}</label>
    <textarea
      v-if="multiline"
      :id="id"
      :value="modelValue"
      class="field-input field-textarea"
      v-bind="$attrs"
      @input="onInput"
    />
    <input
      v-else
      :id="id"
      :type="type"
      :value="modelValue"
      class="field-input"
      v-bind="$attrs"
      @input="onInput"
    />
  </div>
</template>

<style scoped>
.field-group {
  display: flex;
  flex-direction: column;
  gap: 0.4rem;
}

.field-label {
  font-size: 0.85rem;
  font-weight: 500;
  color: var(--text-secondary);
}

.field-input {
  padding: 0.55rem 0.75rem;
  border: 1px solid var(--border-default);
  border-radius: var(--radius-lg);
  background: var(--bg-subtle);
  color: var(--text-primary);
  font-size: 0.9rem;
  font-family: var(--font-sans);
  outline: none;
}

.field-input:focus {
  outline: 2px solid var(--primary);
  outline-offset: 1px;
}

.field-textarea {
  resize: vertical;
  min-height: 80px;
}
</style>
