<template>
  <view class="app-page">
    <view class="container app-card">
    <swiper
      :autoplay="true"
      :circular="true"
      :indicator-dots="true"
      indicator-color="#ffffff"
      indicator-active-color="#22ccff"
      :interval="2000"
    >
      <swiper-item>
        <image mode="widthFix" src="../../static/images/swp1.png" />
      </swiper-item>
      <swiper-item>
        <image mode="widthFix" src="../../static/images/swp2.png" />
      </swiper-item>
      <swiper-item>
        <image mode="widthFix" src="../../static/images/swp3.png" />
      </swiper-item>
    </swiper>
    <image src="../../static/images/home.png" mode="scaleToFill" />
    <view class="title app-btn" @tap="toEntryPage">进入航班餐食预选</view>
    </view>
  </view>
</template>

<script setup lang="ts">
import { useUserStore } from '@/stores/modules/user'

const userStore = useUserStore()

const toEntryPage = () => {
  if (!userStore.profile?.token) {
    uni.navigateTo({
      url: '/pages/login/login',
    })
    return
  }
  uni.navigateTo({
    url: '/pages/identity/identity',
  })
}
</script>

<style lang="less" scoped>
swiper {
  width: 100%;
  height: calc(100vw * 360 / 810);
  image {
    //图片自适应屏幕大小
    width: 100%;
  }
}

.container {
  margin: 20rpx 40rpx;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-height: calc(100vh - 80rpx);
}

image {
  margin-top: 32rpx;
  width: 300rpx;
  height: 300rpx;
  text-align: center;
}

.title {
  width: 360rpx;
  height: 80rpx;
  font-size: 30rpx;
  text-align: center;
  line-height: 80rpx;
  margin-top: 30rpx;
}
</style>
