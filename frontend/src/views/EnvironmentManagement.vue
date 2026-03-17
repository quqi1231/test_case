<template>
  <div class="env-management">
    <div class="header">
      <h1>⚙️ 环境配置</h1>
    </div>

    <!-- 服务状态 -->
    <el-card class="status-card">
      <template #header>
        <div class="card-header">
          <span>🔍 服务状态</span>
          <el-button type="primary" size="small" @click="checkServices">刷新状态</el-button>
        </div>
      </template>
      <el-row :gutter="20">
        <el-col :span="6" v-for="s in services" :key="s.name">
          <div class="service-item" :class="s.running ? 'running' : 'stopped'">
            <div class="service-icon">{{ s.icon }}</div>
            <div class="service-name">{{ s.name }}</div>
            <div class="service-status">
              <el-tag :type="s.running ? 'success' : 'danger'" size="small">
                {{ s.running ? '运行中' : '已停止' }}
              </el-tag>
            </div>
            <div class="service-port" v-if="s.port">
              端口: {{ s.port }}
            </div>
          </div>
        </el-col>
      </el-row>
    </el-card>

    <!-- 环境变量 -->
    <el-card class="env-card">
      <template #header>
        <div class="card-header">
          <span>🔐 环境变量</span>
          <el-button type="primary" size="small" @click="handleCreate">+ 添加变量</el-button>
        </div>
      </template>
      
      <el-tabs v-model="activeEnv">
        <el-tab-pane label="开发环境" name="dev">
          <el-table :data="filteredVars('dev')" stripe>
            <el-table-column prop="var_key" label="变量名" width="180">
              <template #default="{ row }">
                <span class="var-key">{{ row.var_key }}</span>
              </template>
            </el-table-column>
            <el-table-column label="变量值" min-width="200">
              <template #default="{ row }">
                <span v-if="row.is_secret">{{ showSecret(row.var_value) }}</span>
                <span v-else>{{ row.var_value }}</span>
              </template>
            </el-table-column>
            <el-table-column prop="description" label="描述" min-width="150" />
            <el-table-column label="操作" width="120">
              <template #default="{ row }">
                <el-button type="primary" link @click="handleEdit(row)">编辑</el-button>
                <el-button type="danger" link @click="handleDelete(row)">删除</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>
        
        <el-tab-pane label="测试环境" name="test">
          <el-table :data="filteredVars('test')" stripe>
            <el-table-column prop="var_key" label="变量名" width="180">
              <template #default="{ row }">
                <span class="var-key">{{ row.var_key }}</span>
              </template>
            </el-table-column>
            <el-table-column label="变量值" min-width="200">
              <template #default="{ row }">
                <span v-if="row.is_secret">{{ showSecret(row.var_value) }}</span>
                <span v-else>{{ row.var_value }}</span>
              </template>
            </el-table-column>
            <el-table-column prop="description" label="描述" min-width="150" />
            <el-table-column label="操作" width="120">
              <template #default="{ row }">
                <el-button type="primary" link @click="handleEdit(row)">编辑</el-button>
                <el-button type="danger" link @click="handleDelete(row)">删除</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>
        
        <el-tab-pane label="生产环境" name="prod">
          <el-table :data="filteredVars('prod')" stripe>
            <el-table-column prop="var_key" label="变量名" width="180">
              <template #default="{ row }">
                <span class="var-key">{{ row.var_key }}</span>
              </template>
            </el-table-column>
            <el-table-column label="变量值" min-width="200">
              <template #default="{ row }">
                <span v-if="row.is_secret">{{ showSecret(row.var_value) }}</span>
                <span v-else>{{ row.var_value }}</span>
              </template>
            </el-table-column>
            <el-table-column prop="description" label="描述" min-width="150" />
            <el-table-column label="操作" width="120">
              <template #default="{ row }">
                <el-button type="primary" link @click="handleEdit(row)">编辑</el-button>
                <el-button type="danger" link @click="handleDelete(row)">删除</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>
      </el-tabs>
    </el-card>

    <!-- 添加/编辑对话框 -->
    <el-dialog v-model="dialogVisible" :title="isEdit ? '编辑变量' : '添加变量'" width="500px">
      <el-form :model="form" label-width="100px">
        <el-form-item label="环境">
          <el-select v-model="form.env_name" style="width: 100%">
            <el-option label="开发环境" value="dev" />
            <el-option label="测试环境" value="test" />
            <el-option label="生产环境" value="prod" />
          </el-select>
        </el-form-item>
        <el-form-item label="变量名" required>
          <el-input v-model="form.var_key" placeholder="如: API_TOKEN" />
        </el-form-item>
        <el-form-item label="变量值">
          <el-input v-model="form.var_value" type="textarea" :rows="2" />
        </el-form-item>
        <el-form-item label="描述">
          <el-input v-model="form.description" />
        </el-form-item>
        <el-form-item label="敏感信息">
          <el-switch v-model="form.is_secret" />
          <span style="margin-left: 8px; color: #999">开启后显示为 *****</span>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSave">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted, computed } from 'vue'
import { ElMessage } from 'element-plus'
import axios from 'axios'

const activeEnv = ref('dev')
const envVars = ref<any[]>([])
const dialogVisible = ref(false)
const isEdit = ref(false)
const editingId = ref<number | null>(null)

const services = ref([
  { name: '前端服务', icon: '🌐', port: '5173/5174/5175', running: false },
  { name: '后端服务', icon: '⚡', port: '8000', running: false },
  { name: 'MySQL数据库', icon: '🗄️', port: '3307', running: false },
  { name: 'Redis缓存', icon: '💾', port: '6379', running: false },
])

const form = reactive({
  project_id: 1,
  env_name: 'dev',
  var_key: '',
  var_value: '',
  description: '',
  is_secret: false
})

const filteredVars = (env: string) => {
  return envVars.value.filter(v => v.env_name === env)
}

const showSecret = (value: string) => {
  return value ? '*****' : ''
}

const checkServices = async () => {
  // 检查后端
  try {
    const res = await axios.get('http://localhost:8010/health')
    services.value[1].running = res.status === 200
  } catch {
    services.value[1].running = false
  }
  
  // 检查前端（简单判断）
  services.value[0].running = true  // 如果页面能加载说明前端在运行
  
  // 检查 MySQL
  try {
    const res = await axios.get('http://localhost:8010/api/projects/')
    services.value[2].running = res.status === 200 || res.status === 401
  } catch {
    services.value[2].running = false
  }
  
  // Redis 简化检测
  services.value[3].running = false
}

const loadEnvVars = async () => {
  try {
    const token = localStorage.getItem('token')
    const res = await axios.get('/api/env-variables/?project_id=1', {
      headers: { Authorization: `Bearer ${token}` }
    })
    envVars.value = res.data || []
  } catch (e) {
    console.error('加载环境变量失败', e)
  }
}

const handleCreate = () => {
  isEdit.value = false
  editingId.value = null
  Object.assign(form, {
    project_id: 1,
    env_name: activeEnv.value,
    var_key: '',
    var_value: '',
    description: '',
    is_secret: false
  })
  dialogVisible.value = true
}

const handleEdit = (row: any) => {
  isEdit.value = true
  editingId.value = row.id
  Object.assign(form, row)
  dialogVisible.value = true
}

const handleSave = async () => {
  if (!form.var_key) {
    ElMessage.warning('请输入变量名')
    return
  }
  
  try {
    const token = localStorage.getItem('token')
    if (isEdit.value && editingId.value) {
      await axios.put(`/api/env-variables/${editingId.value}`, form, {
        headers: { Authorization: `Bearer ${token}` }
      })
      ElMessage.success('更新成功')
    } else {
      await axios.post('/api/env-variables/', form, {
        headers: { Authorization: `Bearer ${token}` }
      })
      ElMessage.success('添加成功')
    }
    dialogVisible.value = false
    loadEnvVars()
  } catch (e: any) {
    ElMessage.error(e.response?.data?.detail || '操作失败')
  }
}

const handleDelete = async (row: any) => {
  try {
    const token = localStorage.getItem('token')
    await axios.delete(`/api/env-variables/${row.id}`, {
      headers: { Authorization: `Bearer ${token}` }
    })
    ElMessage.success('删除成功')
    loadEnvVars()
  } catch (e: any) {
    ElMessage.error('删除失败')
  }
}

onMounted(() => {
  checkServices()
  loadEnvVars()
})
</script>

<style scoped>
.env-management {
  padding: 20px;
}

.header h1 {
  margin: 0 0 20px 0;
  font-size: 24px;
  color: #303133;
}

.status-card {
  margin-bottom: 20px;
}

.service-item {
  text-align: center;
  padding: 20px;
  border-radius: 8px;
  background: #f5f7fa;
}

.service-item.running {
  background: #f0f9eb;
}

.service-item.stopped {
  background: #fef0f0;
}

.service-icon {
  font-size: 32px;
  margin-bottom: 8px;
}

.service-name {
  font-weight: 500;
  margin-bottom: 8px;
}

.service-port {
  color: #666;
  font-size: 12px;
  margin-top: 4px;
}

.env-card {
  margin-top: 20px;
}

.var-key {
  font-family: monospace;
  background: #f5f7fa;
  padding: 2px 6px;
  border-radius: 4px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
</style>
