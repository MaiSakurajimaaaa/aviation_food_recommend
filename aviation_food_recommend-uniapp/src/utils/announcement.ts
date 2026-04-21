import type { AnnouncementItem } from '@/types/aviation'

const ANNOUNCEMENT_READ_AT_KEY = 'announcementReadAt'

const toTimestamp = (value?: string) => {
  if (!value) return 0
  const timestamp = new Date(String(value)).getTime()
  return Number.isNaN(timestamp) ? 0 : timestamp
}

const getAnnouncementPublishedAt = (item: AnnouncementItem) => {
  return toTimestamp(item.updateTime) || toTimestamp(item.createTime) || 0
}

export const getAnnouncementReadAt = () => {
  const raw = Number(uni.getStorageSync(ANNOUNCEMENT_READ_AT_KEY) || 0)
  return Number.isFinite(raw) && raw > 0 ? raw : 0
}

export const markAnnouncementReadAt = (timestamp = Date.now()) => {
  const safeTimestamp = Number.isFinite(timestamp) && timestamp > 0 ? Math.floor(timestamp) : Date.now()
  uni.setStorageSync(ANNOUNCEMENT_READ_AT_KEY, safeTimestamp)
  return safeTimestamp
}

export const filterActiveAnnouncements = (items: AnnouncementItem[] = []) => {
  return items.filter((item) => Number(item?.status ?? 1) === 1)
}

export const sortAnnouncementsByTime = (items: AnnouncementItem[] = []) => {
  return [...items].sort((a, b) => getAnnouncementPublishedAt(b) - getAnnouncementPublishedAt(a))
}

export const getNewestAnnouncementTime = (items: AnnouncementItem[] = []) => {
  return items.reduce((max, item) => {
    return Math.max(max, getAnnouncementPublishedAt(item))
  }, 0)
}

export const countUnreadAnnouncements = (items: AnnouncementItem[] = [], readAt = getAnnouncementReadAt()) => {
  if (!items.length) return 0
  if (!readAt) return items.length
  return items.reduce((count, item) => {
    return getAnnouncementPublishedAt(item) > readAt ? count + 1 : count
  }, 0)
}

export const formatAnnouncementTime = (value?: string) => {
  if (!value) return '-'
  return String(value).replace('T', ' ').slice(0, 16)
}
