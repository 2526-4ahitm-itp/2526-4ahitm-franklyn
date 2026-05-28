<script setup lang="ts">
import { computed } from 'vue'

defineOptions({
  name: 'UiIcon',
})

interface Props {
  name: string
  label?: string
}

const props = defineProps<Props>()

const hasLabel = computed(() => !!props.label)
</script>

<template>
  <i
    :class="['bi', `bi-${name}`]"
    :aria-label="label"
    :aria-hidden="!hasLabel"
    :role="hasLabel ? 'img' : undefined"
  />
</template>

<style scoped>
.bi {
  display: inline-block;
  font-style: normal;
  font-variant: normal;
  text-rendering: auto;
  line-height: 1;
}
</style>
