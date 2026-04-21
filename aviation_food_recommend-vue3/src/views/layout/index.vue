<script setup lang="ts" name="layout">
import { useRouter, useRoute } from 'vue-router'
import { ElMessageBox, ElMessage } from 'element-plus'
import { useUserInfoStore } from '@/store'
import { ref, reactive, computed } from 'vue'
import { fixPwdAPI } from '@/api/employee'
import type { FormInstance, FormRules } from 'element-plus'
import { isSuperAdmin } from '@/utils/authz'

const dialogFormVisible = ref(false)
const formLabelWidth = '80px'
const isCollapse = ref(false)

const menuList = [
  {
    title: '航空总览',
    path: '/dashboard',
    icon: 'PieChart',
  },
  {
    title: '航班运营中心',
    path: '/flights',
    icon: 'Guide',
  },
  {
    title: '航班管理中心',
    path: '/flight-center',
    icon: 'DataLine',
  },
  {
    title: '航班餐食中心',
    path: '/flight-meal-center',
    icon: 'Food',
  },
  {
    title: '用户餐食中心',
    path: '/user-meal-center',
    icon: 'User',
  },
  {
    title: '餐食资源中心',
    path: '/foods',
    icon: 'Food',
  },
  {
    title: '公告管理中心',
    path: '/preferences',
    icon: 'DataAnalysis',
  },
  {
    title: '评分管理中心',
    path: '/rating-center',
    icon: 'Star',
  },
  {
    title: '管理人员',
    path: '/employee',
    icon: 'Setting',
  },
]

const form = reactive({
  oldPwd: '',
  newPwd: '',
  rePwd: '',
})
const pwdRef = ref<FormInstance>()
const status = ref(1)

const samePwd = (_rule: unknown, value: string, callback: (error?: Error) => void) => {
  if (value !== form.newPwd) {
    callback(new Error('两次输入的密码不一致!'))
  } else {
    callback()
  }
}

const rules: FormRules = {
  oldPwd: [
    { required: true, message: '请输入原密码', trigger: 'blur' },
    {
      pattern: /^[a-zA-Z0-9]{1,10}$/,
      message: '原密码必须是1-10的大小写字母数字',
      trigger: 'blur',
    },
  ],
  newPwd: [
    { required: true, message: '请输入新密码', trigger: 'blur' },
    { pattern: /^\S{6,15}$/, message: '新密码必须是6-15的非空字符', trigger: 'blur' },
  ],
  rePwd: [
    { required: true, message: '请再次输入新密码', trigger: 'blur' },
    { pattern: /^\S{6,15}$/, message: '新密码必须是6-15的非空字符', trigger: 'blur' },
    { validator: samePwd, trigger: 'blur' },
  ],
}

const router = useRouter()
const userInfoStore = useUserInfoStore()
const route = useRoute()

const getActiveAside = () => route.path

const visibleMenuList = computed(() => {
  const currentAccount = userInfoStore.userInfo?.account
  return menuList.filter((item) => item.path !== '/employee' || isSuperAdmin(currentAccount))
})

const currentMenuTitle = computed(() => {
  return visibleMenuList.value.find((item) => item.path === route.path)?.title || '模块页'
})

const cancelForm = () => {
  ElMessage({
    type: 'info',
    message: '已取消修改',
  })
  dialogFormVisible.value = false
}

const fixPwd = async () => {
  const valid = await pwdRef.value?.validate()
  if (!valid) {
    return false
  }
  const submitForm = {
    oldPwd: form.oldPwd,
    newPwd: form.newPwd,
  }
  const { data: res } = await fixPwdAPI(submitForm)
  if (res.code !== 0) {
    return
  }
  ElMessage({
    type: 'success',
    message: '修改成功',
  })
  dialogFormVisible.value = false
}

const quitFn = () => {
  ElMessageBox.confirm('确认退出管理端吗？', '退出登录', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    type: 'warning',
  })
    .then(() => {
      ElMessage({
        type: 'success',
        message: '退出成功',
      })
      userInfoStore.userInfo = null
      router.push('/login')
    })
    .catch(() => {
      ElMessage({
        type: 'info',
        message: '已取消退出',
      })
    })
}
</script>

<template>
  <div class="common-layout">
    <el-dialog v-model="dialogFormVisible" title="修改密码" width="500">
      <el-form :model="form" :rules="rules" ref="pwdRef">
        <el-form-item prop="oldPwd" label="原密码" :label-width="formLabelWidth">
          <el-input v-model="form.oldPwd" autocomplete="off" />
        </el-form-item>
        <el-form-item prop="newPwd" label="新密码" :label-width="formLabelWidth">
          <el-input v-model="form.newPwd" autocomplete="off" />
        </el-form-item>
        <el-form-item prop="rePwd" label="确认密码" :label-width="formLabelWidth">
          <el-input v-model="form.rePwd" autocomplete="off" />
        </el-form-item>
      </el-form>
      <template #footer>
        <div class="dialog-footer">
          <el-button @click="cancelForm">取消</el-button>
          <el-button type="primary" @click="fixPwd">确定</el-button>
        </div>
      </template>
    </el-dialog>

    <el-container>
      <el-header>
        <div class="header-left">
          <div class="logo-text">航空旅客智能美食推荐系统</div>
          <el-button class="collapse-trigger" circle @click="isCollapse = !isCollapse">
            <el-icon>
              <Expand v-if="isCollapse" />
              <Fold v-else />
            </el-icon>
          </el-button>
          <div class="status">{{ status === 1 ? '航空推荐模式' : '维护模式' }}</div>
        </div>

        <div class="header-right">
          <el-dropdown>
            <el-button type="primary" class="account-btn">
              {{ userInfoStore.userInfo ? userInfoStore.userInfo.account : '未登录' }}
              <el-icon class="arrow-down-icon"><ArrowDown /></el-icon>
            </el-button>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item @click="dialogFormVisible = true">修改密码</el-dropdown-item>
                <el-dropdown-item @click="quitFn">退出登录</el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
        </div>
      </el-header>

      <el-container class="box1">
        <aside class="aside-wrap" :class="{ collapsed: isCollapse }">
          <el-menu :default-active="getActiveAside()" :collapse="isCollapse" unique-opened router class="nav-menu">
            <template v-for="item in visibleMenuList" :key="item.path">
              <el-menu-item :index="item.path">
                <el-icon>
                  <component :is="item.icon" />
                </el-icon>
                <span>{{ item.title }}</span>
              </el-menu-item>
            </template>
          </el-menu>
        </aside>

        <el-container class="mycontainer">
          <el-main>
            <div class="content-shell">
              <div class="content-top">
                <el-breadcrumb separator="/">
                  <el-breadcrumb-item>管理控制台</el-breadcrumb-item>
                  <el-breadcrumb-item>{{ currentMenuTitle }}</el-breadcrumb-item>
                </el-breadcrumb>
                <el-tag effect="light" type="info">当前模块：{{ currentMenuTitle }}</el-tag>
              </div>

              <div class="content-body">
                <router-view />
              </div>
            </div>
          </el-main>

          <el-footer>© 2026 航空旅客智能美食推荐系统 · Graduation Project</el-footer>
        </el-container>
      </el-container>
    </el-container>
  </div>
</template>

<style lang="less" scoped>
.common-layout {
  min-height: 100%;
}

.el-header {
  height: 64px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 18px;
  padding: 0 18px;
  color: #fff;
  background: linear-gradient(135deg, #0a77c5 0%, #1399d3 52%, #2db6df 100%);
  border-bottom: 1px solid rgba(255, 255, 255, 0.26);
  box-shadow: 0 10px 26px rgba(14, 78, 128, 0.25);
}

.header-left {
  display: flex;
  align-items: center;
  gap: 10px;
  min-width: 360px;
}

.logo-text {
  font-size: 18px;
  font-weight: 700;
  color: #fff;
  letter-spacing: 0.8px;
  white-space: nowrap;
}

.collapse-trigger {
  border: none;
  color: #0a6ea6;
  background: rgba(255, 255, 255, 0.88);
}

.status {
  display: inline-flex;
  align-items: center;
  height: 30px;
  padding: 0 12px;
  border-radius: 999px;
  background: rgba(255, 192, 76, 0.92);
  color: #fff;
  font-size: 13px;
  font-weight: 600;
}

.header-right {
  min-width: 130px;
  display: flex;
  justify-content: flex-end;
}

.account-btn {
  border: none;
  background: rgba(255, 255, 255, 0.24);
  color: #fff;
}

.arrow-down-icon {
  margin-left: 6px;
}

.box1 {
  display: flex;
  min-height: calc(100vh - 64px);
}

.aside-wrap {
  width: 220px;
  transition: width 180ms ease;
  background: linear-gradient(185deg, #0f2a47 0%, #153b63 100%);
  border-right: 1px solid #22517d;
}

.aside-wrap.collapsed {
  width: 72px;
}

.nav-menu {
  border-right: none;
  background: transparent;
}

.nav-menu :deep(.el-menu) {
  border-right: none;
  background: transparent;
  padding-top: 16px;
}

.nav-menu :deep(.el-menu-item) {
  margin: 8px 10px;
  border-radius: 12px;
  color: #d9ecff;
}

.nav-menu :deep(.el-menu-item:hover) {
  background: rgba(75, 162, 226, 0.22);
}

.nav-menu :deep(.el-menu-item.is-active) {
  background: linear-gradient(135deg, #0f8fdd 0%, #42bbe7 100%);
  color: #fff;
}

.mycontainer {
  flex: 1;
  display: flex;
  min-width: 0;
  flex-direction: column;
}

.el-main {
  padding: 0;
  background: transparent;
}

.content-shell {
  height: 100%;
  min-height: calc(100vh - 64px - 44px);
  display: flex;
  padding: 14px 18px 18px;
  flex-direction: column;
}

.content-top {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 14px;
  border-radius: 12px;
  border: 1px solid #dbe8f5;
  background: rgba(255, 255, 255, 0.86);
}

.content-body {
  flex: 1;
  min-height: 0;
  margin-top: 12px;
  overflow: auto;
}

.el-footer {
  height: 44px;
  font-size: 12px;
  color: #6d8094;
  border-top: 1px solid #deebf6;
  background: rgba(255, 255, 255, 0.76);
  display: flex;
  align-items: center;
  justify-content: center;
}

@media (max-width: 1280px) {
  .logo-text {
    font-size: 16px;
  }
}

@media (max-width: 980px) {
  .status {
    display: none;
  }

  .header-left {
    min-width: 240px;
  }
}
</style>