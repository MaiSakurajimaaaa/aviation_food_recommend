import { useUserStore } from '@/stores/modules/user'

export const useAuthGuard = () => {
  const userStore = useUserStore()

  const ensureLogin = () => {
    if (!userStore.profile?.token || !userStore.profile?.id) {
      uni.reLaunch({ url: '/pages/login/login' })
      return false
    }
    return true
  }

  return {
    userStore,
    ensureLogin,
  }
}
