<script setup lang="ts">
import { onShow } from '@dcloudio/uni-app'
import { useUserStore } from '@/stores/modules/user'

onShow(() => {
  const userStore = useUserStore()
  const pages = getCurrentPages()
  const currentRoute = pages[pages.length - 1]?.route || ''
  const isLoginPage = currentRoute === 'pages/login/login'
  const hasToken = !!userStore.profile?.token

  if (!hasToken && !isLoginPage) {
    setTimeout(() => {
      uni.reLaunch({ url: '/pages/login/login' })
    }, 0)
    return
  }

  if (hasToken && isLoginPage) {
    setTimeout(() => {
      uni.switchTab({ url: '/pages/flight/flight' })
    }, 0)
  }
})
</script>

<style>
@import '@/static/styles/iconfont.css';

.app-page {
  min-height: 100vh;
  padding: 24rpx;
  background: linear-gradient(180deg, #eef8ff 0%, #f8fbff 100%);
}

.app-card {
  background: #fff;
  border-radius: 20rpx;
  padding: 24rpx;
  margin-bottom: 20rpx;
  box-shadow: 0 8rpx 20rpx rgba(34, 170, 238, 0.08);
}

.app-title {
  font-size: 32rpx;
  font-weight: 700;
  color: #114477;
}

.app-subtitle {
  margin-top: 8rpx;
  font-size: 24rpx;
  line-height: 1.7;
  color: #6282a0;
}

.app-input {
  border: 1px solid #d4e6f7;
  border-radius: 12rpx;
  padding: 16rpx;
}

.app-btn,
.app-btn--ghost {
  border-radius: 12rpx;
  font-size: 28rpx;
}

.app-btn {
  background: #00aaff;
  color: #fff;
}

.app-btn--ghost {
  background: #eef8ff;
  color: #00aaff;
  border: 1px solid #00aaff;
}
</style>
