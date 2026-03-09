import { createRouter, createWebHistory } from 'vue-router'
import { useUserInfoStore } from '@/store'
import { isSuperAdmin } from '@/utils/authz'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      component: () => import('./views/layout/index.vue'),
      redirect: '/dashboard', // 将dashboard设为首页home
      children: [
        {
          path: 'dashboard',
          name: 'dashboard',
          // lazy loading
          component: () => import('./views/dashboard/index.vue')
        },
        {
          path: 'employee',
          name: 'employee',
          component: () => import('./views/employee/index.vue')
        },
        {
          path: 'employee/add',
          name: 'employee_add',
          component: () => import('./views/employee/add.vue')
        },
        {
          path: 'employee/update',
          name: 'employee_update',
          component: () => import('./views/employee/update.vue')
        },
        {
          path: 'flights',
          name: 'flights',
          component: () => import('./views/flights/index.vue')
        },
        {
          path: 'flight-center',
          name: 'flight_center',
          component: () => import('./views/flightCenter/index.vue')
        },
        {
          path: 'flight-meal-center',
          name: 'flight_meal_center',
          component: () => import('./views/flightMealCenter/index.vue')
        },
        {
          path: 'user-meal-center',
          name: 'user_meal_center',
          component: () => import('./views/userMealCenter/index.vue')
        },
        {
          path: 'foods',
          name: 'foods',
          component: () => import('./views/foods/index.vue')
        },
        {
          path: 'preferences',
          name: 'preferences',
          component: () => import('./views/preferences/index.vue')
        },
        {
          path: 'rating-center',
          name: 'rating_center',
          component: () => import('./views/ratingCenter/index.vue')
        }
      ]
    },
    {
      path: '/login',
      name: 'login',
      // lazy loading
      component: () => import('./views/login/index.vue')
    },
    {
      path: '/:pathMatch(.*)*',
      redirect: '/dashboard'
    }
  ]
})

router.beforeEach((to) => {
  if (to.path === '/login') {
    return true
  }
  const userInfoStore = useUserInfoStore()
  const token = userInfoStore.userInfo?.token
  const account = userInfoStore.userInfo?.account
  if (!token) {
    return '/login'
  }
  if (to.path.startsWith('/employee') && !isSuperAdmin(account)) {
    return '/dashboard'
  }
  return true
})

export default router
