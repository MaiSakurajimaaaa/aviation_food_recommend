export const MEAL_TYPE_LABEL_MAP: Record<string, string> = {
  '1': '儿童餐',
  '2': '标准餐',
  '3': '清真餐',
  '4': '素食餐',
}

export const MEAL_TYPE_OPTIONS = [
  { value: '1', label: '儿童餐' },
  { value: '2', label: '标准餐' },
  { value: '3', label: '清真餐' },
  { value: '4', label: '素食餐' },
]

export const MEAL_TYPE_FILTER_OPTIONS = [
  { value: '', label: '全部餐型' },
  ...MEAL_TYPE_OPTIONS,
]

export const getMealTypeLabel = (value?: number | string, fallback = '标准餐') => {
  if (value == null || value === '') {
    return fallback
  }
  const key = String(value)
  return MEAL_TYPE_LABEL_MAP[key] || fallback
}

export const mapMealTypeValues = (values: Array<string | number>) => {
  return values.map((item) => getMealTypeLabel(item, String(item)))
}
