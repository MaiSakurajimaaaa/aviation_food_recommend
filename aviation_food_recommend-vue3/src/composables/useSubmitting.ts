import { ref } from 'vue'

export const useSubmitting = () => {
  const submitting = ref(false)

  const guard = async <T>(task: () => Promise<T>) => {
    if (submitting.value) {
      return null
    }
    submitting.value = true
    try {
      return await task()
    } finally {
      submitting.value = false
    }
  }

  return {
    submitting,
    guard,
  }
}
