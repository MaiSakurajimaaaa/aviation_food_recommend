<template>
  <view class="page">
    <view class="blur blur-a"></view>
    <view class="blur blur-b"></view>

    <view class="hero card">
      <view>
        <view class="hero-kicker">AERO BROADCAST HUB</view>
        <view class="hero-title">公告中心</view>
        <view class="hero-desc">系统公告、航班提醒与服务通知统一查看。</view>
      </view>
      <view class="hero-badge">{{ announcements.length }} 条</view>
    </view>

    <view class="card stats-card">
      <view class="stat-item">
        <view class="stat-value">{{ announcements.length }}</view>
        <view class="stat-label">全部公告</view>
      </view>
      <view class="stat-item">
        <view class="stat-value">{{ unreadCount }}</view>
        <view class="stat-label">进入前未读</view>
      </view>
      <button class="refresh-btn" @click="loadData">{{ loading ? '同步中...' : '刷新' }}</button>
    </view>

    <view class="card empty-card" v-if="!loading && !announcements.length">
      <view class="empty-title">暂无公告</view>
      <view class="empty-desc">航班选餐提醒、系统通知将在这里显示。</view>
    </view>

    <view class="card notice-item" v-for="item in announcements" :key="item.id">
      <view class="notice-head">
        <view class="notice-title">{{ item.title || '系统公告' }}</view>
        <view class="notice-time">{{ formatAnnouncementTime(item.updateTime || item.createTime) }}</view>
      </view>
      <view class="notice-content">{{ item.content || '暂无公告内容' }}</view>
      <view class="notice-tags">
        <view class="tag">公告ID #{{ item.id }}</view>
        <view class="tag" v-if="item.flightId">航班 {{ item.flightId }}</view>
      </view>
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { onPullDownRefresh, onShow } from '@dcloudio/uni-app'
import { getAnnouncementListAPI } from '@/api/recommendation'
import {
  countUnreadAnnouncements,
  filterActiveAnnouncements,
  formatAnnouncementTime,
  getAnnouncementReadAt,
  getNewestAnnouncementTime,
  markAnnouncementReadAt,
  sortAnnouncementsByTime,
} from '@/utils/announcement'
import type { AnnouncementItem } from '@/types/aviation'

const announcements = ref<AnnouncementItem[]>([])
const unreadCount = ref(0)
const loading = ref(false)

const markCurrentBatchAsRead = () => {
  const newest = getNewestAnnouncementTime(announcements.value)
  const nextReadAt = newest > 0 ? Math.max(newest, Date.now()) : Date.now()
  markAnnouncementReadAt(nextReadAt)
}

const loadData = async () => {
  loading.value = true
  try {
    const res = await getAnnouncementListAPI()
    const activeAnnouncements = sortAnnouncementsByTime(filterActiveAnnouncements(res.data || []))
    const readAt = getAnnouncementReadAt()
    announcements.value = activeAnnouncements
    unreadCount.value = countUnreadAnnouncements(activeAnnouncements, readAt)
    markCurrentBatchAsRead()
  } catch {
    // http utility already shows error toast; prevent unhandled rejection
  } finally {
    loading.value = false
    uni.stopPullDownRefresh()
  }
}

onShow(() => {
  void loadData()
})

onPullDownRefresh(() => {
  void loadData()
})
</script>

<style scoped>
.page {
  --bg-a: #edf6ff;
  --bg-b: #f3fffa;
  --bg-c: #fff6ea;
  --ink-1: #132f4a;
  --line: #dbe8f5;
  --brand-1: #0c7fcd;
  --brand-2: #12a6de;
  min-height: 100vh;
  padding: 24rpx;
  background: linear-gradient(158deg, var(--bg-a) 0%, var(--bg-b) 50%, var(--bg-c) 100%);
  font-family: 'DIN Alternate', 'Avenir Next', 'PingFang SC', sans-serif;
  position: relative;
  overflow: hidden;
}

.blur {
  position: absolute;
  border-radius: 999rpx;
  z-index: 0;
  opacity: 0.52;
  filter: blur(16rpx);
}

.blur-a {
  width: 280rpx;
  height: 280rpx;
  right: -80rpx;
  top: 140rpx;
  background: #80d5ff;
}

.blur-b {
  width: 240rpx;
  height: 240rpx;
  left: -70rpx;
  bottom: 130rpx;
  background: #ffd9a4;
}

.card {
  position: relative;
  z-index: 2;
  background: rgba(255, 255, 255, 0.94);
  border-radius: 30rpx;
  border: 1px solid var(--line);
  padding: 24rpx;
  margin-bottom: 18rpx;
  box-shadow: 0 20rpx 42rpx rgba(17, 56, 94, 0.1);
  animation: rise-in 360ms ease both;
}

.hero {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: linear-gradient(138deg, #0b76c2 0%, #1299d1 52%, #35b5dd 100%);
  border-color: rgba(255, 255, 255, 0.3);
}

.hero-kicker {
  color: rgba(255, 255, 255, 0.9);
  font-size: 20rpx;
  letter-spacing: 2rpx;
}

.hero-title {
  margin-top: 4rpx;
  color: #fff;
  font-size: 42rpx;
  font-weight: 800;
}

.hero-desc {
  margin-top: 10rpx;
  color: rgba(255, 255, 255, 0.92);
  font-size: 24rpx;
}

.hero-badge {
  min-width: 130rpx;
  padding: 10rpx 18rpx;
  border-radius: 999rpx;
  text-align: center;
  color: #fff;
  font-size: 24rpx;
  border: 1px solid rgba(255, 255, 255, 0.36);
  background: rgba(255, 255, 255, 0.22);
}

.stats-card {
  display: flex;
  align-items: center;
  gap: 10rpx;
  background: linear-gradient(130deg, #eef8ff 0%, #fff 48%, #fff5e6 100%);
}

.stat-item {
  flex: 1;
  border-radius: 18rpx;
  border: 1px solid #dceaf6;
  background: rgba(255, 255, 255, 0.8);
  padding: 12rpx;
}

.stat-value {
  color: #194668;
  font-size: 32rpx;
  font-weight: 700;
}

.stat-label {
  margin-top: 4rpx;
  color: #6c849b;
  font-size: 22rpx;
}

.refresh-btn {
  width: 140rpx;
  height: 72rpx;
  line-height: 72rpx;
  border-radius: 36rpx;
  color: #fff;
  font-size: 24rpx;
  background: linear-gradient(135deg, var(--brand-1) 0%, var(--brand-2) 100%);
}

.empty-card {
  border-style: dashed;
}

.empty-title {
  color: #1e3a56;
  font-size: 30rpx;
  font-weight: 700;
}

.empty-desc {
  margin-top: 8rpx;
  color: #6d8499;
  font-size: 23rpx;
}

.notice-item {
  background: linear-gradient(140deg, #ffffff 0%, #f4fbff 100%);
}

.notice-head {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 14rpx;
}

.notice-title {
  color: var(--ink-1);
  font-size: 31rpx;
  font-weight: 700;
  flex: 1;
}

.notice-time {
  color: #6e879e;
  font-size: 22rpx;
}

.notice-content {
  margin-top: 10rpx;
  color: #355775;
  line-height: 1.75;
  font-size: 25rpx;
}

.notice-tags {
  margin-top: 12rpx;
  display: flex;
  flex-wrap: wrap;
  gap: 8rpx;
}

.tag {
  padding: 6rpx 12rpx;
  border-radius: 999rpx;
  border: 1px solid #d5e7f7;
  background: #f3f9ff;
  color: #2f638f;
  font-size: 22rpx;
}

@keyframes rise-in {
  from {
    opacity: 0;
    transform: translateY(12rpx);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
</style>
