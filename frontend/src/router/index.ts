import { createRouter, createWebHistory } from 'vue-router'
import ProjectManagement from '../views/ProjectManagement.vue'
import EnvironmentManagement from '../views/EnvironmentManagement.vue'
import InterfaceManagement from '../views/InterfaceManagement.vue'
import InterfaceExecute from '../views/InterfaceExecute.vue'
import CaseManagement from '../views/CaseManagement.vue'
import TestSuites from '../views/TestSuites.vue'
import TestExecution from '../views/TestExecution.vue'
import TestProjects from '../views/TestProjects.vue'
import Login from '../views/Login.vue'

const routes = [
  {
    path: '/login',
    name: 'Login',
    component: Login
  },
  {
    path: '/',
    redirect: '/projects'
  },
  {
    path: '/projects',
    name: 'ProjectManagement',
    component: ProjectManagement,
    meta: { requiresAuth: true }
  },
  {
    path: '/interfaces',
    name: 'InterfaceManagement',
    component: InterfaceManagement,
    meta: { requiresAuth: true }
  },
  {
    path: '/interfaces/execute',
    name: 'InterfaceExecute',
    component: InterfaceExecute,
    meta: { requiresAuth: true }
  },
  {
    path: '/cases',
    name: 'CaseManagement',
    component: CaseManagement,
    meta: { requiresAuth: true }
  },
  {
    path: '/environments',
    name: 'EnvironmentManagement',
    component: EnvironmentManagement,
    meta: { requiresAuth: true }
  },
  {
    path: '/test-projects',
    name: 'TestProjects',
    component: TestProjects,
    meta: { requiresAuth: true }
  },
  {
    path: '/test-suites',
    name: 'TestSuites',
    component: TestSuites,
    meta: { requiresAuth: true }
  },
  {
    path: '/test-execution',
    name: 'TestExecution',
    component: TestExecution,
    meta: { requiresAuth: true }
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

// 导航守卫
router.beforeEach((to, from, next) => {
  const token = localStorage.getItem('token')
  
  if (to.meta.requiresAuth && !token) {
    next('/login')
  } else if (to.path === '/login' && token) {
    next('/projects')
  } else {
    next()
  }
})

export default router
