<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { addDishAPI, deleteDishesAPI, getDishPageListAPI, updateDishAPI, updateDishStatusAPI } from '@/api/dish'
import { getCategoryPageListAPI } from '@/api/category'
import type { CategoryItem, DishItem, DishUpsertPayload } from '@/types/aviation'
import type { ElTable } from 'element-plus'
import type { UploadFile, UploadRawFile } from 'element-plus'
import { useSubmitting } from '@/composables/useSubmitting'
import { MEAL_TYPE_OPTIONS, buildMealTypeDisplay, getMealTypeLabel, inferMealTypeByCategoryName } from '@/utils/meal'

const loading = ref(false)
const dishList = ref<DishItem[]>([])
const categoryList = ref<CategoryItem[]>([])
const selectedRows = ref<DishItem[]>([])
const tableRef = ref<InstanceType<typeof ElTable>>()
const editDialogVisible = ref(false)
const isEdit = ref(false)
const { submitting, guard: withSubmitting } = useSubmitting()

const dishForm = reactive({
  id: undefined as number | undefined,
  name: '',
  pic: '',
  detail: '',
  categoryId: undefined as number | undefined,
  mealType: undefined as number | undefined,
  flavorTags: [] as string[],
  stock: 0,
  status: 1,
})

const query = reactive({
  name: '',
  categoryId: undefined as number | undefined,
  status: undefined as number | undefined,
  page: 1,
  pageSize: 8,
  total: 0,
})

const flavorTypeOptions = ['清淡', '微辣', '中辣', '重辣', '低脂', '高蛋白']

const loadCategories = async () => {
  const { data: res } = await getCategoryPageListAPI({ page: 1, pageSize: 200, type: 1 })
  categoryList.value = res?.data?.records || []
}

const loadDishes = async () => {
  loading.value = true
  const { data: res } = await getDishPageListAPI({
    name: query.name,
    categoryId: query.categoryId,
    status: query.status,
    page: query.page,
    pageSize: query.pageSize,
  })
  loading.value = false
  dishList.value = res?.data?.records || []
  query.total = res?.data?.total || 0
}

const normalizeFlavorTags = (input: string[]) => {
  const normalized = (input || []).map((item) => String(item).trim()).filter(Boolean)
  return JSON.stringify(normalized)
}

const parseFlavorTagsForSelect = (raw?: string) => {
  if (!raw) return []
  const value = String(raw)
  try {
    const parsed = JSON.parse(value)
    if (Array.isArray(parsed)) {
      return parsed.map((item) => String(item).trim()).filter(Boolean)
    }
    return []
  } catch {
    return value.split(/[，,]/).map((item) => item.trim()).filter(Boolean)
  }
}

const validateFlavorSelection = (selected: string[]) => {
  const hasMild = selected.includes('清淡')
  const hasSpicy = selected.some((item) => item === '微辣' || item === '中辣' || item === '重辣')
  if (hasMild && hasSpicy) {
    ElMessage.warning('“清淡”不可与辣味类型同时选择，请调整选择类型')
    return false
  }
  return true
}

const formatFlavorTags = (raw: string) => {
  if (!raw) return '未设置'
  try {
    const parsed = JSON.parse(String(raw))
    return Array.isArray(parsed) ? parsed.join('、') : String(raw)
  } catch {
    return String(raw)
  }
}

const resetForm = () => {
  dishForm.id = undefined
  dishForm.name = ''
  dishForm.pic = ''
  dishForm.detail = ''
  dishForm.categoryId = undefined
  dishForm.mealType = undefined
  dishForm.flavorTags = []
  dishForm.stock = 0
  dishForm.status = 1
}

const openAddDialog = () => {
  isEdit.value = false
  resetForm()
  editDialogVisible.value = true
}

const openEditDialog = (row: DishItem) => {
  isEdit.value = true
  dishForm.id = row.id
  dishForm.name = row.name || ''
  dishForm.pic = row.pic || ''
  dishForm.detail = row.detail || ''
  dishForm.categoryId = row.categoryId
  dishForm.mealType = row.mealType
  dishForm.flavorTags = parseFlavorTagsForSelect(row.flavorTags)
  dishForm.stock = row.stock ?? 0
  dishForm.status = row.status ?? 1
  editDialogVisible.value = true
}

const handleDishCategoryChange = (categoryId?: number) => {
  const categoryName = getCategoryName(categoryId)
  const suggestedMealType = inferMealTypeByCategoryName(categoryName)
  if (!suggestedMealType) {
    return
  }
  if (!dishForm.mealType) {
    dishForm.mealType = suggestedMealType
    ElMessage.info(`已按分类自动带出餐型：${getMealTypeLabel(suggestedMealType)}`)
    return
  }
  if (dishForm.mealType !== suggestedMealType) {
    ElMessage.warning(`当前分类通常对应${getMealTypeLabel(suggestedMealType)}，请确认餐型是否设置正确`)
  }
}

const convertFileToBase64 = (file: File) => {
  return new Promise<string>((resolve, reject) => {
    const reader = new FileReader()
    reader.readAsDataURL(file)
    reader.onload = () => resolve(String(reader.result || ''))
    reader.onerror = () => reject(new Error('图片读取失败'))
  })
}

const handleImageChange = async (file: UploadFile) => {
  const rawFile = file.raw as UploadRawFile | undefined
  if (!rawFile) {
    return
  }
  if (!rawFile.type.startsWith('image/')) {
    ElMessage.warning('请上传图片文件')
    return
  }
  try {
    dishForm.pic = await convertFileToBase64(rawFile)
    ElMessage.success('图片已加载')
  } catch {
    ElMessage.error('图片处理失败，请重试')
  }
}

const saveDish = async () => {
  if (!dishForm.name.trim()) {
    ElMessage.warning('请输入餐食名称')
    return
  }
  if (!dishForm.categoryId) {
    ElMessage.warning('请选择分类')
    return
  }
  if (!dishForm.mealType) {
    ElMessage.warning('请选择餐型')
    return
  }
  if (dishForm.stock < 0) {
    ElMessage.warning('库存不能小于0')
    return
  }

  if (!validateFlavorSelection(dishForm.flavorTags)) {
    return
  }

  const suggestedMealType = inferMealTypeByCategoryName(getCategoryName(dishForm.categoryId))
  if (suggestedMealType && suggestedMealType !== dishForm.mealType) {
    ElMessage.warning(`分类与餐型存在偏差，建议餐型：${getMealTypeLabel(suggestedMealType)}`)
  }

  const normalizedFlavorTags = normalizeFlavorTags(dishForm.flavorTags)

  await withSubmitting(async () => {
    const payload: DishUpsertPayload = {
      id: dishForm.id,
      name: dishForm.name.trim(),
      detail: dishForm.detail,
      pic: dishForm.pic,
      categoryId: dishForm.categoryId!,
      status: dishForm.status,
      mealType: dishForm.mealType!,
      flavorTags: normalizedFlavorTags,
      stock: Number(dishForm.stock || 0),
      flavors: [],
    }

    const request = isEdit.value
      ? updateDishAPI(payload)
      : addDishAPI({
          ...payload,
          id: undefined,
          status: 1,
        })
    const { data: res } = await request
    if (res.code !== 0) {
      return
    }
    ElMessage.success(isEdit.value ? '餐食已更新' : '餐食已新增')
    editDialogVisible.value = false
    await loadDishes()
  })
}

const changeStatus = async (row: DishItem) => {
  await updateDishStatusAPI(row.id)
  ElMessage.success(row.status === 1 ? '已停售' : '已启用')
  await loadDishes()
}

const deleteDish = async (row: DishItem) => {
  await ElMessageBox.confirm('删除后不可恢复，是否继续？', '提示', {
    confirmButtonText: '确认删除',
    cancelButtonText: '取消',
    type: 'warning',
  })
  const { data: res } = await deleteDishesAPI(String(row.id))
  if (res.code !== 0) {
    return
  }
  ElMessage.success('删除成功')
  await loadDishes()
}

const onSelectionChange = (rows: DishItem[]) => {
  selectedRows.value = rows
}

const clearSelection = () => {
  selectedRows.value = []
  tableRef.value?.clearSelection?.()
}

const ensureSelection = () => {
  if (selectedRows.value.length === 0) {
    ElMessage.warning('请先选择餐食')
    return false
  }
  return true
}

const bulkDelete = async () => {
  if (!ensureSelection()) {
    return
  }
  await ElMessageBox.confirm('将删除选中的餐食，是否继续？', '提示', {
    confirmButtonText: '确认删除',
    cancelButtonText: '取消',
    type: 'warning',
  })
  const ids = selectedRows.value.map((item) => item.id).join(',')
  const { data: res } = await deleteDishesAPI(ids)
  if (res.code !== 0) {
    return
  }
  ElMessage.success('批量删除成功')
  await loadDishes()
  clearSelection()
}

const bulkSetStatus = async (targetStatus: 0 | 1) => {
  if (!ensureSelection()) {
    return
  }
  const actionText = targetStatus === 1 ? '启用' : '停售'
  await ElMessageBox.confirm(`将${actionText}选中的餐食，是否继续？`, '提示', {
    confirmButtonText: `确认${actionText}`,
    cancelButtonText: '取消',
    type: 'warning',
  })
  const pendingRows = selectedRows.value.filter((item) => item.status !== targetStatus)
  if (pendingRows.length === 0) {
    ElMessage.info(`所选餐食已全部为${targetStatus === 1 ? '启用' : '停用'}状态`)
    return
  }
  await Promise.all(pendingRows.map((item) => updateDishStatusAPI(item.id)))
  ElMessage.success(`批量${actionText}成功`)
  await loadDishes()
  clearSelection()
}

const getCategoryName = (categoryId?: number) => {
  if (!categoryId) return '-'
  return categoryList.value.find((item) => item.id === categoryId)?.name || '-'
}

const getMealTypeDisplay = (row: DishItem) => {
  const categoryName = getCategoryName(row.categoryId)
  return buildMealTypeDisplay(row.mealType, categoryName)
}

const resetQuery = () => {
  query.name = ''
  query.categoryId = undefined
  query.status = undefined
  query.page = 1
  loadDishes()
}

const handleCurrentChange = (val: number) => {
  query.page = val
  loadDishes()
}

onMounted(async () => {
  await loadCategories()
  await loadDishes()
})
</script>

<template>
  <el-card>
    <template #header>餐食资源中心</template>

    <el-alert type="info" show-icon :closable="false" style="margin-bottom: 14px">
      <template #title>
        航空餐食要求：机上餐食为免费，无需价格；请维护餐型（1儿童/2标准/3清真/4素食）与选择类型，推荐引擎会基于该字段匹配。
      </template>
    </el-alert>

    <div class="toolbar">
      <el-input v-model="query.name" placeholder="菜品名" style="width: 220px" clearable />
      <el-select v-model="query.categoryId" placeholder="菜品分类" clearable style="width: 220px">
        <el-option v-for="item in categoryList" :key="item.id" :label="item.name" :value="item.id" />
      </el-select>
      <el-select v-model="query.status" placeholder="状态" clearable style="width: 140px">
        <el-option :value="1" label="启用" />
        <el-option :value="0" label="停用" />
      </el-select>
      <el-button type="primary" @click="query.page = 1; loadDishes()">查询</el-button>
      <el-button @click="resetQuery">重置</el-button>
      <el-button type="success" @click="openAddDialog">新增餐食</el-button>
      <el-button type="danger" plain @click="bulkDelete">批量删除</el-button>
      <el-button type="success" plain @click="bulkSetStatus(1)">批量启用</el-button>
      <el-button type="warning" plain @click="bulkSetStatus(0)">批量停售</el-button>
    </div>

    <el-table ref="tableRef" :data="dishList" border v-loading="loading" stripe @selection-change="onSelectionChange">
      <el-table-column type="selection" width="50" />
      <el-table-column prop="id" label="ID" width="70" />
      <el-table-column prop="name" label="菜品名" min-width="140" />
      <el-table-column label="图片" width="90">
        <template #default="scope">
          <el-image
            v-if="scope.row.pic"
            :src="scope.row.pic"
            fit="cover"
            style="width: 48px; height: 48px; border-radius: 4px"
            :preview-src-list="[scope.row.pic]"
            preview-teleported
          />
          <span v-else>-</span>
        </template>
      </el-table-column>
      <el-table-column label="分类" min-width="120">
        <template #default="scope">{{ getCategoryName(scope.row.categoryId) }}</template>
      </el-table-column>
      <el-table-column label="餐型" min-width="120">
        <template #default="scope">{{ getMealTypeDisplay(scope.row) }}</template>
      </el-table-column>
      <el-table-column label="选择类型" min-width="180">
        <template #default="scope">{{ formatFlavorTags(scope.row.flavorTags) }}</template>
      </el-table-column>
      <el-table-column prop="stock" label="库存" width="90" />
      <el-table-column label="状态" width="100">
        <template #default="scope">
          <el-tag :type="scope.row.status === 1 ? 'success' : 'info'">
            {{ scope.row.status === 1 ? '启用' : '停用' }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column label="操作" width="260">
        <template #default="scope">
          <el-button type="primary" link @click="openEditDialog(scope.row)">编辑</el-button>
          <el-button
            :type="scope.row.status === 1 ? 'danger' : 'success'"
            link
            @click="changeStatus(scope.row)"
          >
            {{ scope.row.status === 1 ? '停售' : '启用' }}
          </el-button>
          <el-button type="danger" link @click="deleteDish(scope.row)">删除</el-button>
        </template>
      </el-table-column>
      <template #empty>
        <el-empty description="暂无菜品资源" />
      </template>
    </el-table>

    <el-pagination
      class="page"
      background
      layout="total, prev, pager, next"
      :total="query.total"
      :page-size="query.pageSize"
      :current-page="query.page"
      @current-change="handleCurrentChange"
    />

    <el-dialog v-model="editDialogVisible" :title="isEdit ? '编辑餐食' : '新增餐食'" width="560px">
      <el-form label-width="100px">
        <el-form-item label="名称" required>
          <el-input v-model="dishForm.name" placeholder="请输入餐食名称" maxlength="50" show-word-limit />
        </el-form-item>
        <el-form-item label="分类" required>
          <el-select v-model="dishForm.categoryId" placeholder="请选择分类" style="width: 100%" @change="handleDishCategoryChange">
            <el-option v-for="item in categoryList" :key="item.id" :label="item.name" :value="item.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="图片">
          <el-upload :auto-upload="false" :show-file-list="false" accept="image/*" @change="handleImageChange">
            <el-button type="primary" plain>选择图片</el-button>
          </el-upload>
          <el-image
            v-if="dishForm.pic"
            :src="dishForm.pic"
            fit="cover"
            style="width: 64px; height: 64px; margin-left: 12px; border-radius: 4px"
            :preview-src-list="[dishForm.pic]"
            preview-teleported
          />
        </el-form-item>
        <el-form-item label="描述">
          <el-input v-model="dishForm.detail" type="textarea" :rows="2" maxlength="200" show-word-limit />
        </el-form-item>
        <el-form-item label="餐型">
          <el-select v-model="dishForm.mealType" placeholder="请选择餐型" style="width: 100%">
            <el-option v-for="option in MEAL_TYPE_OPTIONS" :key="option.value" :value="option.value" :label="option.label" />
          </el-select>
        </el-form-item>
        <el-form-item label="选择类型">
          <el-select
            v-model="dishForm.flavorTags"
            placeholder="请选择类型（可多选）"
            style="width: 100%"
            multiple
            clearable
            collapse-tags
            collapse-tags-tooltip
          >
            <el-option v-for="item in flavorTypeOptions" :key="item" :label="item" :value="item" />
          </el-select>
        </el-form-item>
        <el-form-item label="库存" required>
          <el-input-number v-model="dishForm.stock" :min="0" :max="999999" style="width: 100%" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="editDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="submitting" @click="saveDish">保存</el-button>
      </template>
    </el-dialog>
  </el-card>
</template>

<style scoped>
.toolbar {
  display: flex;
  gap: 12px;
  align-items: center;
  margin-bottom: 14px;
}

.page {
  margin-top: 14px;
  justify-content: center;
}
</style>
