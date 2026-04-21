import type { DishItem } from '@/types/aviation'

export const MEAL_TYPE_LABEL_MAP: Record<number, string> = {
  1: '儿童餐',
  2: '标准餐',
  3: '清真餐',
  4: '素食餐',
}

export const MEAL_TYPE_OPTIONS = [
  { value: 1, label: '儿童餐' },
  { value: 2, label: '标准餐' },
  { value: 3, label: '清真餐' },
  { value: 4, label: '素食餐' },
]

const CATEGORY_MEAL_HINT_RULES = [
  { keyword: '儿童', mealType: 1 },
  { keyword: '清真', mealType: 3 },
  { keyword: '素', mealType: 4 },
  { keyword: '早餐', mealType: 2 },
]

export const inferMealTypeByCategoryName = (categoryName?: string) => {
  const name = String(categoryName || '').trim()
  if (!name) return undefined
  const matched = CATEGORY_MEAL_HINT_RULES.find((rule) => name.includes(rule.keyword))
  return matched?.mealType
}

export const getMealTypeLabel = (mealType?: number) => {
  if (!mealType) return '未设置'
  return MEAL_TYPE_LABEL_MAP[mealType] || '未设置'
}

export const buildMealTypeDisplay = (mealType: DishItem['mealType'], categoryName?: string) => {
  const label = getMealTypeLabel(mealType)
  if (!mealType || label === '未设置') {
    return label
  }
  const suggestedMealType = inferMealTypeByCategoryName(categoryName)
  if (!suggestedMealType) {
    return label
  }
  if (suggestedMealType === mealType) {
    return `${label}（与分类一致）`
  }
  return `${label}（建议：${getMealTypeLabel(suggestedMealType)}）`
}
