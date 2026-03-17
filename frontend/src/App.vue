<template>
  <div id="app">
    <el-container style="min-height: 100vh">
      <!-- 侧边栏 -->
      <el-aside width="200px" class="sidebar">
        <div class="logo">
          <h2>📋 项目管理</h2>
        </div>
        <el-menu
          :default-active="activeMenu"
          class="el-menu-vertical"
          router
          :collapse-transition="false"
        >
          <el-menu-item index="/projects">
            <el-icon><FolderOpened /></el-icon>
            <span>项目管理</span>
          </el-menu-item>
          
          <!-- 接口管理子菜单 -->
          <el-sub-menu index="/interfaces">
            <template #title>
              <el-icon><Connection /></el-icon>
              <span>接口管理</span>
            </template>
            <el-menu-item index="/interfaces">
              <span>接口列表</span>
            </el-menu-item>
            <el-menu-item index="/interfaces/execute">
              <span>接口执行</span>
            </el-menu-item>
          </el-sub-menu>
          
          <el-menu-item index="/cases">
            <el-icon><Document /></el-icon>
            <span>用例管理</span>
          </el-menu-item>
          <el-menu-item index="/environments">
            <el-icon><Setting /></el-icon>
            <span>环境配置</span>
          </el-menu-item>
        </el-menu>
      </el-aside>

      <!-- 主内容 -->
      <el-container>
        <el-header class="header">
          <div class="user-info">
            <el-dropdown>
              <span class="user-dropdown">
                <el-icon><User /></el-icon>
                管理员
                <el-icon><ArrowDown /></el-icon>
              </span>
              <template #dropdown>
                <el-dropdown-menu>
                  <el-dropdown-item>个人中心</el-dropdown-item>
                  <el-dropdown-item divided>退出登录</el-dropdown-item>
                </el-dropdown-menu>
              </template>
            </el-dropdown>
          </div>
        </el-header>
        
        <el-main>
          <router-view />
        </el-main>
      </el-container>
    </el-container>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRoute } from 'vue-router'
import { 
  FolderOpened, Setting, User, ArrowDown, Connection, Document
} from '@element-plus/icons-vue'

const route = useRoute()
const activeMenu = computed(() => route.path)
</script>

<style>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
}

#app {
  height: 100vh;
}

.sidebar {
  background: #304156;
}

.logo {
  height: 60px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #263445;
}

.logo h2 {
  color: #fff;
  font-size: 18px;
  margin: 0;
}

.el-menu-vertical {
  border-right: none;
  background: #304156;
}

.el-menu-item,
.el-sub-menu__title {
  color: #bfcbd9;
  transition: none !important;
}

.el-menu-item:hover,
.el-menu-item.is-active,
.el-sub-menu__title:hover {
  background: #263445 !important;
  color: #409eff !important;
}

.header {
  background: #fff;
  display: flex;
  align-items: center;
  justify-content: flex-end;
  padding: 0 20px;
  border-bottom: 1px solid #e6e6e6;
}

.user-info {
  display: flex;
  align-items: center;
}

.user-dropdown {
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
  padding: 8px 12px;
  border-radius: 4px;
}

.user-dropdown:hover {
  background: #f5f7fa;
}

.el-main {
  background: #f0f2f5;
  padding: 0;
}
</style>
