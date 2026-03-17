<template>
  <!-- 隐藏的文件导入input -->
  <input type="file" id="importInput" accept=".json,.xlsx" style="display: none" @change="handleFileChange" />
  
  <div class="interface-management">
    <el-card>
      <!-- 顶部导航 -->
      <div class="header">
        <h1>🔌 接口管理</h1>
        <div class="header-actions">
          <el-dropdown @command="handleCommand">
            <el-button type="primary">
              更多操作 <el-icon><ArrowDown /></el-icon>
            </el-button>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item command="template">📥 下载模板</el-dropdown-item>
                <el-dropdown-item command="import">📤 导入接口</el-dropdown-item>
                <el-dropdown-item command="export">📋 导出接口</el-dropdown-item>
                <el-dropdown-item command="collection">📁 新建接口集合</el-dropdown-item>
                <el-dropdown-item command="chain">🔗 执行链</el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
          <el-button type="primary" @click="handleCreate">
            <el-icon><Plus /></el-icon>新建接口
          </el-button>
          <el-input
            v-model="searchText"
            placeholder="搜索接口名称/代码"
            style="width: 200px; margin-left: 12px"
            clearable
            @keyup.enter="handleSearch"
            @clear="handleSearch"
          >
            <template #prefix>
              <el-icon><Search /></el-icon>
            </template>
          </el-input>
        </div>
      </div>

      <!-- Tab 切换 -->
      <el-tabs v-model="activeTab" type="card">
        <el-tab-pane label="接口列表" name="list">
          <!-- 接口列表 -->
          <el-table :data="interfaces" v-loading="loading" stripe>
        <el-table-column prop="api_code" label="接口代码" width="120">
          <template #default="{ row }">
            <el-tag size="small">{{ row.api_code }}</el-tag>
          </template>
        </el-table-column>
        
        <el-table-column prop="api_name" label="接口名称" min-width="150">
          <template #default="{ row }">
            <span class="interface-name">{{ row.api_name }}</span>
          </template>
        </el-table-column>
        
        <el-table-column label="模块/集合" min-width="150">
          <template #default="{ row }">
            <el-tag v-if="row.module_id" size="small" type="info">
              {{ getModuleName(row.module_id) }}
            </el-tag>
            <el-tag v-if="row.collection_id" size="small" type="success" style="margin-left: 4px">
              {{ getCollectionName(row.collection_id) }}
            </el-tag>
          </template>
        </el-table-column>
        
        <el-table-column label="方法" width="80">
          <template #default="{ row }">
            <el-tag :type="getMethodType(row.method)">{{ row.method }}</el-tag>
          </template>
        </el-table-column>
        
        <el-table-column prop="path" label="接口路径" min-width="180" />
        
        <el-table-column prop="priority" label="优先级" width="80">
          <template #default="{ row }">
            <el-tag v-if="row.priority" :type="getPriorityType(row.priority)" size="small">
              {{ row.priority }}
            </el-tag>
          </template>
        </el-table-column>
        
        <el-table-column prop="protocol" label="协议" width="70" />
        
        <el-table-column label="最近执行" width="150">
          <template #default="{ row }">
            <el-tag v-if="row.last_status_code" :type="row.last_status_code < 400 ? 'success' : 'danger'" size="small">
              {{ row.last_status_code }}
            </el-tag>
            <span v-else style="color: #999">-</span>
            <span v-if="row.last_response_time" style="margin-left: 4px; color: #666; font-size: 12px">
              {{ row.last_response_time }}ms
            </span>
            <div v-if="row.last_response_body && row.last_response_body.includes('error')" style="color: #f56c6c; font-size: 11px; margin-top: 2px">
              {{ row.last_response_body.substring(0, 50) }}...
            </div>
          </template>
        </el-table-column>
        
        <el-table-column label="耗时" width="80">
          <template #default="{ row }">
            <span v-if="row.last_response_time">{{ row.last_response_time }}ms</span>
            <span v-else style="color: #999">-</span>
          </template>
        </el-table-column>
        
        <el-table-column label="状态" width="80">
          <template #default="{ row }">
            <el-tag :type="row.is_active ? 'success' : 'info'" size="small">
              {{ row.is_active ? '启用' : '禁用' }}
            </el-tag>
          </template>
        </el-table-column>
        
        <el-table-column label="操作" width="150" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" link @click="handleEdit(row)">
              <el-icon><Edit /></el-icon>
            </el-button>
            <el-button type="danger" link @click="handleDelete(row)">
              <el-icon><Delete /></el-icon>
            </el-button>
          </template>
        </el-table-column>
      </el-table>
        </el-tab-pane>
        <el-tab-pane label="接口执行" name="execute">
          <InterfaceExecute />
        </el-tab-pane>
      </el-tabs>
    </el-card>

    <!-- 创建/编辑弹窗 -->
    <el-dialog v-model="dialogVisible" :title="isEdit ? '编辑接口' : '新建接口'" width="700px">
      <el-form :model="form" :rules="rules" ref="formRef" label-width="100px">
        <el-row :gutter="20">
          <el-col :span="8">
            <el-form-item label="所属模块" prop="module_id">
              <el-select v-model="form.module_id" placeholder="选择模块" style="width: 100%" @change="form.collection_id = null">
                <el-option v-for="m in modules" :key="m.id" :label="m.module_name" :value="m.id" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="接口集合" prop="collection_id">
              <el-select v-model="form.collection_id" placeholder="选择集合" style="width: 100%" allow-clear>
                <el-option v-for="c in collections.filter(col => col.module_id === form.module_id)" :key="c.id" :label="c.name" :value="c.id" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="接口代码" prop="api_code">
              <el-input v-model="form.api_code" placeholder="如: user.login" />
            </el-form-item>
          </el-col>
        </el-row>
        
        <el-form-item label="接口名称" prop="api_name">
          <el-input v-model="form.api_name" placeholder="用户登录接口" />
        </el-form-item>
        
        <el-row :gutter="20">
          <el-col :span="8">
            <el-form-item label="请求方法">
              <el-select v-model="form.method" style="width: 100%">
                <el-option label="GET" value="GET" />
                <el-option label="POST" value="POST" />
                <el-option label="PUT" value="PUT" />
                <el-option label="DELETE" value="DELETE" />
                <el-option label="PATCH" value="PATCH" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="16">
            <el-form-item label="接口路径" prop="path">
              <el-input v-model="form.path" placeholder="/api/users/{id}" />
            </el-form-item>
          </el-col>
        </el-row>
        
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="协议">
              <el-select v-model="form.protocol" style="width: 100%">
                <el-option label="HTTP" value="http" />
                <el-option label="HTTPS" value="https" />
                <el-option label="WebSocket" value="websocket" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="Content-Type">
              <el-select v-model="form.content_type" style="width: 100%">
                <el-option label="application/json" value="application/json" />
                <el-option label="application/x-www-form-urlencoded" value="application/x-www-form-urlencoded" />
                <el-option label="multipart/form-data" value="multipart/form-data" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="优先级">
              <el-select v-model="form.priority" placeholder="可选" clearable style="width: 100%">
                <el-option label="P0 - 核心" value="P0" />
                <el-option label="P1 - 重要" value="P1" />
                <el-option label="P2 - 一般" value="P2" />
                <el-option label="P3 - 低" value="P3" />
              </el-select>
            </el-form-item>
          </el-col>
        </el-row>
        
        <el-form-item label="接口描述">
          <el-input v-model="form.description" type="textarea" :rows="2" />
        </el-form-item>
        
        <el-form-item label="请求示例">
          <el-input v-model="form.request_example" type="textarea" :rows="3" placeholder='{"username": "admin", "password": "123456"}' />
        </el-form-item>
        
        <el-form-item label="响应示例">
          <el-input v-model="form.response_example" type="textarea" :rows="3" placeholder='{"code": 0, "message": "success"}' />
        </el-form-item>
      </el-form>
      
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSubmit" :loading="submitting">保存</el-button>
      </template>
    </el-dialog>

    <!-- 新建接口集合对话框 -->
    <el-dialog v-model="collectionDialogVisible" title="新建接口集合" width="500px">
      <el-form :model="collectionForm" label-width="100px">
        <el-form-item label="所属模块">
          <el-select v-model="collectionForm.module_id" placeholder="选择模块" style="width: 100%">
            <el-option v-for="m in modules" :key="m.id" :label="m.module_name" :value="m.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="集合名称" required>
          <el-input v-model="collectionForm.name" placeholder="如: 用户认证、订单管理" />
        </el-form-item>
        <el-form-item label="描述">
          <el-input v-model="collectionForm.description" type="textarea" :rows="3" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="collectionDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSaveCollection">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted, defineAsyncComponent } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Edit, Delete, ArrowDown, Upload, Download, Connection, Search } from '@element-plus/icons-vue'
import axios from 'axios'

const InterfaceExecute = defineAsyncComponent(() => import('./InterfaceExecute.vue'))

const activeTab = ref('list')

const API_BASE_URL = ''

// 数据
const interfaces = ref<any[]>([])
const searchText = ref('')
const modules = ref<any[]>([])
const collections = ref<any[]>([])
const loading = ref(false)
const submitting = ref(false)
const dialogVisible = ref(false)
const collectionDialogVisible = ref(false)
const collectionForm = ref({ project_id: 1, module_id: null as number | null, name: '', description: '' })
const isEdit = ref(false)
const editingId = ref<number | null>(null)

const form = reactive({
  project_id: 1,
  module_id: null,
  collection_id: null,
  api_code: '',
  api_name: '',
  method: 'GET',
  path: '',
  protocol: 'http',
  content_type: 'application/json',
  priority: null,
  description: '',
  request_example: '',
  response_example: ''
})

const rules = {
  api_code: [{ required: true, message: '请输入接口代码', trigger: 'blur' }],
  api_name: [{ required: true, message: '请输入接口名称', trigger: 'blur' }],
  path: [{ required: true, message: '请输入接口路径', trigger: 'blur' }]
}

const formRef = ref()

// 加载数据
const loadData = async () => {
  loading.value = true
  try {
    // 加载模块
    const token = localStorage.getItem('token')
    const modulesRes = await axios.get(`${API_BASE_URL}/api/projects/1/modules`, {
      headers: { Authorization: `Bearer ${token}` }
    })
    modules.value = modulesRes.data
    
    // 加载接口集合
    const collectionsRes = await axios.get(`${API_BASE_URL}/api/collections/?project_id=1`, {
      headers: { Authorization: `Bearer ${token}` }
    })
    collections.value = collectionsRes.data || []
    
    // 加载接口
    const interfacesRes = await axios.get(`${API_BASE_URL}/api/interfaces/?project_id=1`)
    let allInterfaces = interfacesRes.data?.items || interfacesRes.data
    
    // 前端搜索过滤
    if (searchText.value) {
      const keyword = searchText.value.toLowerCase()
      allInterfaces = allInterfaces.filter((i: any) => 
        i.api_name?.toLowerCase().includes(keyword) || 
        i.api_code?.toLowerCase().includes(keyword) ||
        i.path?.toLowerCase().includes(keyword)
      )
    }
    interfaces.value = allInterfaces
  } catch (error: any) {
    ElMessage.error(error.response?.data?.detail || '加载失败')
  } finally {
    loading.value = false
  }
}

// 搜索接口
const handleSearch = () => {
  loadData()
}

// 获取模块名称
const getModuleName = (moduleId: number) => {
  const module = modules.value.find(m => m.id === moduleId)
  return module?.module_name || ''
}

// 获取接口集合名称
const getCollectionName = (collectionId: number) => {
  const collection = collections.value.find(c => c.id === collectionId)
  return collection?.name || ''
}

// 获取方法类型颜色
const getMethodType = (method: string) => {
  const map: Record<string, string> = {
    GET: 'success',
    POST: 'primary',
    PUT: 'warning',
    DELETE: 'danger',
    PATCH: 'info'
  }
  return map[method] || 'info'
}

// 获取优先级颜色
const getPriorityType = (priority: string) => {
  const map: Record<string, string> = {
    P0: 'danger',
    P1: 'warning',
    P2: 'info',
    P3: ''
  }
  return map[priority] || ''
}

// 创建接口
const handleCreate = () => {
  isEdit.value = false
  Object.assign(form, {
    project_id: 1,
    module_id: null,
    api_code: '',
    api_name: '',
    method: 'GET',
    path: '',
    protocol: 'http',
    content_type: 'application/json',
    description: '',
    request_example: '',
    response_example: ''
  })
  dialogVisible.value = true
}

// 编辑接口
const handleEdit = (row: any) => {
  isEdit.value = true
  editingId.value = row.id
  Object.assign(form, row)
  dialogVisible.value = true
}

// 保存接口集合
const handleSaveCollection = async () => {
  if (!collectionForm.value.name) {
    ElMessage.warning('请输入集合名称')
    return
  }
  
  try {
    const token = localStorage.getItem('token')
    await axios.post(`${API_BASE_URL}/api/collections/`, collectionForm.value, {
      headers: { Authorization: `Bearer ${token}` }
    })
    ElMessage.success('创建成功')
    collectionDialogVisible.value = false
    // 重新加载接口集合
    const res = await axios.get(`${API_BASE_URL}/api/collections/?project_id=1`, {
      headers: { Authorization: `Bearer ${token}` }
    })
    collections.value = res.data || []
  } catch (e: any) {
    ElMessage.error(e.response?.data?.detail || '创建失败')
  }
}

// 提交
const handleSubmit = async () => {
  await formRef.value?.validate()
  submitting.value = true
  
  try {
    const token = localStorage.getItem('token')
    
    if (isEdit.value && editingId.value) {
      await axios.put(`${API_BASE_URL}/api/interfaces/${editingId.value}`, form, {
        headers: { Authorization: `Bearer ${token}` }
      })
      ElMessage.success('保存成功')
    } else {
      await axios.post(`${API_BASE_URL}/api/interfaces/`, form, {
        headers: { Authorization: `Bearer ${token}` }
      })
      ElMessage.success('创建成功')
    }
    
    dialogVisible.value = false
    loadData()
  } catch (error: any) {
    ElMessage.error(error.response?.data?.detail || '操作失败')
  } finally {
    submitting.value = false
  }
}

// 删除
const handleDelete = async (row: any) => {
  try {
    await ElMessageBox.confirm(`确定删除接口 "${row.api_name}" 吗?`, '提示', { type: 'warning' })
    
    const token = localStorage.getItem('token')
    await axios.delete(`${API_BASE_URL}/api/interfaces/${row.id}`, {
      headers: { Authorization: `Bearer ${token}` }
    })
    ElMessage.success('删除成功')
    loadData()
  } catch (error) {
    // 用户取消
  }
}

// 更多操作
const handleCommand = async (command: string) => {
  const token = localStorage.getItem('token')
  
  switch (command) {
    case 'template':
      // 下载模板
      try {
        const res = await axios.get('/api/interfaces/template?format=json', {
          headers: { Authorization: `Bearer ${token}` },
          responseType: 'blob'
        })
        const url = window.URL.createObjectURL(new Blob([res.data]))
        const a = document.createElement('a')
        a.href = url
        a.download = 'interface_template.json'
        a.click()
        window.URL.revokeObjectURL(url)
        ElMessage.success('模板下载成功')
      } catch (e) {
        ElMessage.error('模板下载失败')
      }
      break
      
    case 'import':
      // 触发文件选择
      (document.getElementById('importInput') as HTMLInputElement)?.click()
      break
      
    case 'export':
      // 导出接口
      try {
        const res = await axios.get('/api/interfaces/?project_id=1', {
          headers: { Authorization: `Bearer ${token}` }
        })
        const data = res.data?.items || res.data || []
        const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' })
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = 'interfaces.json'
        a.click()
        URL.revokeObjectURL(url)
        ElMessage.success(`导出成功: ${data.length} 个接口`)
      } catch (e) {
        ElMessage.error('导出失败')
      }
      break
      
    case 'chain':
      ElMessage.info('执行链功能开发中...')
      break
      
    case 'collection':
      // 新建接口集合
      collectionDialogVisible.value = true
      collectionForm.value = { project_id: 1, module_id: null, name: '', description: '' }
      break
  }
}

// 导入文件
const handleFileChange = async (event: Event) => {
  const file = (event.target as HTMLInputElement).files?.[0]
  if (!file) return
  
  const token = localStorage.getItem('token')
  const formData = new FormData()
  formData.append('file', file)
  
  try {
    const res = await axios.post('/api/interfaces/import?project_id=1', formData, {
      headers: { 
        Authorization: `Bearer ${token}`,
        'Content-Type': 'multipart/form-data'
      }
    })
    ElMessage.success(`导入成功: ${res.data.length || 0} 个接口`)
    loadData()
  } catch (e: any) {
    ElMessage.error(e.response?.data?.detail || '导入失败')
  }
  
  // 清空input
  (event.target as HTMLInputElement).value = ''
}

onMounted(() => {
  loadData()
})
</script>

<style scoped>
.interface-management {
  padding: 20px;
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.header h1 {
  margin: 0;
  font-size: 24px;
  color: #303133;
}

.interface-card {
  margin-top: 20px;
}

.interface-name {
  font-weight: 500;
}
</style>
