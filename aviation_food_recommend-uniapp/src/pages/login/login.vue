<template>
  <view class="viewport">
    <view class="bg-layer bg-a"></view>
    <view class="bg-layer bg-b"></view>
    <view class="grid-overlay"></view>

    <view class="hero">
      <view class="brand-line">AVIATION MEAL SELECTION</view>
      <image src="@/static/images/login.png" class="logo"></image>
      <view class="title">航班餐食预选</view>
      <view class="desc">先完成微信登录，再进入航班页进行身份冷启动与航班匹配</view>
    </view>

    <view class="panel">
      <view class="panel-title">欢迎登机</view>
      <view class="panel-sub">当前仅开放微信快捷登录，不提供注册入口</view>

      <button class="button" @tap="login" :disabled="submitting">{{ submitting ? '登录中...' : '微信一键登录' }}</button>

      <view class="service-row">
        <view class="dot"></view>
        <text class="service-text">登录即代表你同意《服务条款》与《隐私协议》</text>
      </view>
    </view>
  </view>
</template>

<script lang="ts" setup>
import { loginAPI } from '@/api/login'
import { onLoad } from '@dcloudio/uni-app'
import { useUserStore } from '@/stores/modules/user'
import type { LoginResult } from '@/types/user'
import { ref } from 'vue'

// 先调用wx.login()，获取 code 登录凭证
let code = ''
const submitting = ref(false)

const fetchLoginCode = async () => {
  const res = await wx.login()
  code = res.code
}

onLoad(async () => {
  const userStore = useUserStore()
  if (userStore.profile?.token) {
    uni.switchTab({ url: '/pages/flight/flight' })
    return
  }
  await fetchLoginCode()
})
// 再携带code发送登录请求
// 获取用户手机号码
const login = async () => {
  if (submitting.value) return
  submitting.value = true
  if (!code) {
    await fetchLoginCode()
  }
  if (!code) {
    uni.showToast({ title: '微信登录凭证获取失败，请重试', icon: 'none' })
    submitting.value = false
    return
  }
  try {
    const res = await loginAPI(code)
    if (!res.data) {
      uni.showToast({
        title: '登录失败，请稍后重试',
        icon: 'none',
      })
      return
    }
    loginSuccess(res.data)
  } catch {
    uni.showToast({ title: '登录失败，请稍后重试', icon: 'none' })
  } finally {
    submitting.value = false
  }
}

const loginSuccess = (profile: LoginResult) => {
  // 保存会员信息
  const userStore = useUserStore()
  userStore.setProfile(profile)
  uni.setStorageSync('identityVerified', '0')
  // 成功提示
  uni.showToast({ icon: 'success', title: '登录成功' })
  setTimeout(() => {
    uni.switchTab({ url: '/pages/flight/flight' })
  }, 500)
}
</script>

<style lang="less" scoped>
page {
  height: 100%;
}

.viewport {
  position: relative;
  overflow: hidden;
  min-height: 100vh;
  padding: 64rpx 48rpx 56rpx;
  background: linear-gradient(160deg, #071c36 0%, #0d3865 48%, #13385b 100%);
}

.bg-layer {
  position: absolute;
  border-radius: 50%;
  filter: blur(16rpx);
  opacity: 0.58;
}

.bg-a {
  width: 380rpx;
  height: 380rpx;
  top: -120rpx;
  left: -70rpx;
  background: radial-gradient(circle, #26cbff 0%, rgba(38, 203, 255, 0) 72%);
}

.bg-b {
  width: 420rpx;
  height: 420rpx;
  right: -140rpx;
  bottom: 120rpx;
  background: radial-gradient(circle, #ffad53 0%, rgba(255, 173, 83, 0) 74%);
}

.grid-overlay {
  position: absolute;
  inset: 0;
  background-image:
    linear-gradient(rgba(255, 255, 255, 0.05) 1px, transparent 1px),
    linear-gradient(90deg, rgba(255, 255, 255, 0.05) 1px, transparent 1px);
  background-size: 44rpx 44rpx;
  opacity: 0.26;
}

.hero {
  position: relative;
  z-index: 2;
  margin-top: 88rpx;
  display: flex;
  flex-direction: column;
  align-items: center;
}

.brand-line {
  margin-bottom: 20rpx;
  font-size: 18rpx;
  letter-spacing: 5rpx;
  color: rgba(192, 236, 255, 0.9);
}

.logo {
  width: 214rpx;
  height: 214rpx;
  filter: drop-shadow(0 14rpx 30rpx rgba(6, 15, 33, 0.45));
}

.title {
  margin-top: 24rpx;
  font-size: 56rpx;
  font-weight: 700;
  letter-spacing: 3rpx;
  color: #ebf7ff;
  text-shadow: 0 8rpx 16rpx rgba(0, 0, 0, 0.25);
}

.desc {
  margin-top: 20rpx;
  text-align: center;
  color: rgba(220, 242, 255, 0.86);
  font-size: 26rpx;
  line-height: 1.75;
  padding: 0 18rpx;
}

.panel {
  position: relative;
  z-index: 2;
  margin-top: 120rpx;
  border-radius: 30rpx;
  padding: 38rpx 32rpx 30rpx;
  background: linear-gradient(165deg, rgba(255, 255, 255, 0.23) 0%, rgba(255, 255, 255, 0.11) 100%);
  border: 1rpx solid rgba(193, 235, 255, 0.4);
  box-shadow: 0 22rpx 48rpx rgba(1, 12, 29, 0.36), inset 0 1rpx 0 rgba(255, 255, 255, 0.34);
}

.panel-title {
  text-align: center;
  font-size: 34rpx;
  font-weight: 600;
  color: #f4fbff;
}

.panel-sub {
  margin-top: 10rpx;
  text-align: center;
  font-size: 22rpx;
  color: rgba(222, 241, 255, 0.82);
}

.button {
  margin-top: 30rpx;
  width: 100%;
  height: 92rpx;
  line-height: 92rpx;
  border-radius: 46rpx;
  border: none;
  background: linear-gradient(105deg, #2ad4ff, #2995ff);
  color: #fff;
  font-size: 30rpx;
  font-weight: 600;
  letter-spacing: 2rpx;
  box-shadow: 0 12rpx 24rpx rgba(10, 107, 210, 0.35);
}

.button::after {
  border: none;
}

.button[disabled] {
  opacity: 0.72;
}

.service-row {
  margin-top: 20rpx;
  display: flex;
  align-items: flex-start;
  justify-content: center;
  gap: 10rpx;
}

.dot {
  width: 10rpx;
  height: 10rpx;
  border-radius: 50%;
  background: #99daff;
  margin-top: 10rpx;
}

.service-text {
  font-size: 22rpx;
  color: rgba(212, 235, 249, 0.88);
  line-height: 1.6;
  text-align: center;
}

@media (max-width: 360px) {
  .viewport {
    padding: 50rpx 34rpx;
  }

  .title {
    font-size: 48rpx;
  }

  .panel {
    margin-top: 90rpx;
    padding: 30rpx 24rpx 24rpx;
  }
}
</style>
