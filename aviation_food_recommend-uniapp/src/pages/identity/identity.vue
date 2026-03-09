<template>
  <view class="app-page page">
    <view class="app-card card">
      <view class="app-title title">身份核验</view>
      <view class="app-subtitle desc">请先输入身份证号，系统将查询是否已有关联航班。</view>
      <input class="app-input" v-model="idNumber" placeholder="请输入18位身份证号" maxlength="18" />
      <button type="button" class="app-btn btn" @click="verifyAndRoute">开始查询</button>
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { onLoad } from '@dcloudio/uni-app'
import { useUserStore } from '@/stores/modules/user'
import { getUserInfoAPI, updateUserAPI } from '@/api/user'
import { getCurrentFlightAPI } from '@/api/flight'
import { getPreferenceAPI } from '@/api/preference'

const userStore = useUserStore()
const idNumber = ref('')

const isValidIdCard = (value: string) => {
  return /^[1-9]\d{5}(18|19|20)\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01])\d{3}[0-9Xx]$/.test(value)
}

onLoad(async () => {
  const currentUserId = userStore.profile?.id
  if (!currentUserId) {
    uni.redirectTo({ url: '/pages/login/login' })
    return
  }
  const res = await getUserInfoAPI(currentUserId)
  if (res.data?.idNumber) {
    idNumber.value = res.data.idNumber
  }
})

const verifyAndRoute = async () => {
  uni.setStorageSync('identityVerified', '0')
  const currentUserId = userStore.profile?.id
  if (!currentUserId) {
    uni.redirectTo({ url: '/pages/login/login' })
    return
  }
  if (!idNumber.value) {
    uni.showToast({ title: '请输入身份证号', icon: 'none' })
    return
  }
  if (!isValidIdCard(idNumber.value)) {
    uni.showToast({ title: '身份证号格式不正确', icon: 'none' })
    return
  }

  const userRes = await getUserInfoAPI(currentUserId)
  const existedIdNumber = userRes.data?.idNumber

  if (existedIdNumber && existedIdNumber !== idNumber.value) {
    uni.showToast({ title: '身份证号与当前账号不匹配', icon: 'none' })
    return
  }

  if (!existedIdNumber) {
    await updateUserAPI({
      id: currentUserId,
      idNumber: idNumber.value,
    })
  }

  const flightRes = await getCurrentFlightAPI()
  if (flightRes.data) {
    uni.setStorageSync('identityVerified', '1')
    const preferenceRes = await getPreferenceAPI()
    if (!preferenceRes.data) {
      uni.redirectTo({ url: '/pages/preferences/preferences?first=1' })
      return
    }
    uni.redirectTo({ url: '/pages/recommendation/recommendation' })
  } else {
    uni.showToast({ title: '该身份证未绑定航班，请先联系工作人员', icon: 'none' })
  }
}
</script>

<style scoped>
.card { margin-top: 60rpx; }
.title { margin-bottom: 4rpx; }
.desc { margin-bottom: 20rpx; }
.btn { margin-top: 20rpx; }
</style>
