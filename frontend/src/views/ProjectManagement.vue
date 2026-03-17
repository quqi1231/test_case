<template>
  <div class="project-management">
    <!-- 顶部导航 -->
    <div class="header">
      <h1>📁 项目管理</h1>
      <div class="header-actions">
        <el-button type="primary" @click="handleCreate">
          <el-icon><Plus /></el-icon>新建项目
        </el-button>
      </div>
    </div>

    <!-- 项目列表 -->
    <el-card class="project-card">
      <el-table :data="projects" v-loading="loading" stripe>
        <el-table-column prop="project_code" label="项目代码" width="120">
          <template #default="{ row }">
            <el-tag type="primary">{{ row.project_code }}</el-tag>
          </template>
        </el-table-column>
        
        <el-table-column prop="project_name" label="项目名称" min-width="180">
          <template #default="{ row }">
            <span class="project-name">{{ row.project_name }}</span>
          </template>
        </el-table-column>
        
        <el-table-column prop="git_url" label="Git仓库" min-width="200">
          <template #default="{ row }">
            <a v-if="row.git_url" :href="row.git_url" target="_blank" class="git-link">
              <el-icon><Link /></el-icon>仓库
            </a>
            <span v-else class="text-muted">-</span>
          </template>
        </el-table-column>
        
        <el-table-column prop="jenkins_job" label="Jenkins" width="150">
          <template #default="{ row }">
            {{ row.jenkins_job || '-' }}
          </template>
        </el-table-column>
        
        <el-table-column prop="owner" label="负责人" width="100" />
        
        <el-table-column prop="is_active" label="状态" width="80">
          <template #default="{ row }">
            <el-tag :type="row.is_active ? 'success' : 'info'">
              {{ row.is_active ? '启用' : '禁用' }}
            </el-tag>
          </template>
        </el-table-column>
        
        <el-table-column prop="created_at" label="创建时间" width="120">
          <template #default="{ row }">
            {{ formatDate(row.created_at) }}
          </template>
        </el-table-column>
        
        <el-table-column label="操作" width="180" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" link @click="handleDetail(row)">
              <el-icon><Setting /></el-icon>配置
            </el-button>
            <el-button type="danger" link @click="handleDelete(row)">
              <el-icon><Delete /></el-icon>删除
            </el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 项目详情抽屉 -->
    <el-drawer v-model="detailVisible" :title="currentProject?.project_name" size="60%">
      <el-tabs v-model="activeTab">
        <el-tab-pane label="基本信息" name="info">
          <el-descriptions :column="2" border>
            <el-descriptions-item label="项目代码">
              <el-tag>{{ currentProject?.project_code }}</el-tag>
            </el-descriptions-item>
            <el-descriptions-item label="项目名称">
              {{ currentProject?.project_name }}
            </el-descriptions-item>
            <el-descriptions-item label="Git仓库" :span="2">
              {{ currentProject?.git_url || '-' }}
            </el-descriptions-item>
            <el-descriptions-item label="Jenkins Job">
              {{ currentProject?.jenkins_job || '-' }}
            </el-descriptions-item>
            <el-descriptions-item label="负责人">
              {{ currentProject?.owner || '-' }}
            </el-descriptions-item>
            <el-descriptions-item label="描述" :span="2">
              {{ currentProject?.description || '-' }}
            </el-descriptions-item>
          </el-descriptions>
        </el-tab-pane>
        
        <el-tab-pane label="功能模块" name="modules">
          <div class="module-layout">
            <!-- 左侧：模块列表 -->
            <div class="module-sidebar">
              <div class="sidebar-header">
                <span>模块列表</span>
                <el-button type="primary" link @click="handleCreateModule">
                  <el-icon><Plus /></el-icon>
                </el-button>
              </div>
              <el-scrollbar>
                <div 
                  v-for="m in modules" 
                  :key="m.id" 
                  class="module-item"
                  :class="{ active: currentModule?.id === m.id }"
                  @click="selectModule(m)"
                >
                  <el-tag type="info" size="small">{{ m.module_code }}</el-tag>
                  <span class="module-name">{{ m.module_name }}</span>
                  <el-badge :value="getModuleInterfaces(m.id).length" type="primary" />
                </div>
                <div v-if="!modules.length" class="empty-module">
                  暂无模块，请新建
                </div>
              </el-scrollbar>
            </div>

            <!-- 右侧：模块内容 -->
            <div class="module-content">
              <template v-if="currentModule">
                <div class="content-header">
                  <h3>
                    <el-tag type="info">{{ currentModule.module_code }}</el-tag>
                    {{ currentModule.module_name }}
                  </h3>
                  <div>
                    <el-button type="primary" size="small" @click="showAddInterfacesToModule">
                      <el-icon><Plus /></el-icon>添加接口
                    </el-button>
                    <el-button type="primary" link @click="handleEditModule(currentModule)">编辑</el-button>
                    <el-popconfirm title="确认删除?" @confirm="handleDeleteModule(currentModule.id)">
                      <template #reference><el-button type="danger" link>删除</el-button></template>
                    </el-popconfirm>
                  </div>
                </div>

                <el-tabs v-model="moduleTab">
                  <el-tab-pane label="接口列表" name="interfaces">
                    <el-table :data="moduleInterfaces" v-loading="moduleInterfacesLoading">
                      <el-table-column prop="name" label="接口名称" />
                      <el-table-column prop="method" label="方法" width="80">
                        <template #default="{row}">
                          <el-tag :type="getMethodType(row.method)">{{ row.method }}</el-tag>
                        </template>
                      </el-table-column>
                      <el-table-column prop="url" label="URL" show-overflow-tooltip />
                      <el-table-column label="操作" width="150">
                        <template #default="{row}">
                          <el-button type="primary" link @click="viewInterfaceDetail(row)">详情</el-button>
                          <el-button type="danger" link @click="removeInterfaceFromModule(row.id)">移除</el-button>
                        </template>
                      </el-table-column>
                    </el-table>
                    <el-empty v-if="!moduleInterfaces.length" description="暂无关联接口，点击上方添加" />
                  </el-tab-pane>
                  
                  <el-tab-pane label="测试用例" name="cases">
                    <el-empty description="基于页面的测试用例功能开发中" />
                  </el-tab-pane>
                </el-tabs>
              </template>
              
              <el-empty v-else description="请选择左侧模块" />
            </div>
          </div>

          <!-- 新建/编辑模块对话框 -->
          <el-dialog v-model="moduleDialogVisible" :title="isEditModule ? '编辑模块' : '新建模块'" width="500px">
            <el-form :model="moduleForm" label-width="80px">
              <el-form-item label="模块代码" required>
                <el-input v-model="moduleForm.module_code" placeholder="如: user" />
              </el-form-item>
              <el-form-item label="模块名称" required>
                <el-input v-model="moduleForm.module_name" placeholder="如: 用户模块" />
              </el-form-item>
              <el-form-item label="层级">
                <el-input-number v-model="moduleForm.level" :min="1" :max="10" />
              </el-form-item>
            </el-form>
            <template #footer>
              <el-button @click="moduleDialogVisible = false">取消</el-button>
              <el-button type="primary" @click="handleSaveModule">保存</el-button>
            </template>
          </el-dialog>

          <!-- 添加接口到模块对话框 -->
          <el-dialog v-model="addModuleInterfaceDialogVisible" title="添加接口到模块" width="800px">
            <el-table 
              ref="interfaceTableRef"
              :data="availableInterfaces" 
              v-loading="interfacesLoading"
              @selection-change="handleModuleInterfaceSelection"
            >
              <el-table-column type="selection" width="40" />
              <el-table-column prop="name" label="接口名称" />
              <el-table-column prop="method" label="方法" width="80">
                <template #default="{row}">
                  <el-tag :type="getMethodType(row.method)">{{ row.method }}</el-tag>
                </template>
              </el-table-column>
              <el-table-column prop="url" label="URL" show-overflow-tooltip />
              <el-table-column prop="module_name" label="所属模块">
                <template #default="{row}">
                  <el-tag v-if="row.module_name" type="info" size="small">{{ row.module_name }}</el-tag>
                  <span v-else class="text-muted">-</span>
                </template>
              </el-table-column>
            </el-table>
            <template #footer>
              <el-button @click="addModuleInterfaceDialogVisible = false">取消</el-button>
              <el-button type="primary" @click="saveModuleInterfaces" :disabled="!selectedModuleInterfaces.length">
                添加选中 ({{ selectedModuleInterfaces.length }})
              </el-button>
            </template>
          </el-dialog>

          <!-- 接口详情对话框 -->
          <el-dialog v-model="interfaceDetailDialogVisible" :title="`${currentInterface?.name || '接口'} 详情`" width="700px">
            <template v-if="currentInterface">
              <el-descriptions :column="2" border>
                <el-descriptions-item label="接口名称">{{ currentInterface.name }}</el-descriptions-item>
                <el-descriptions-item label="方法">
                  <el-tag :type="getMethodType(currentInterface.method)">{{ currentInterface.method }}</el-tag>
                </el-descriptions-item>
                <el-descriptions-item label="URL" :span="2">
                  <code>{{ currentInterface.url }}</code>
                </el-descriptions-item>
                <el-descriptions-item label="描述" :span="2">{{ currentInterface.description || '-' }}</el-descriptions-item>
              </el-descriptions>

              <el-divider>请求头</el-divider>
              <pre class="code-block">{{ JSON.stringify(currentInterface.headers || {}, null, 2) }}</pre>

              <el-divider>Query参数</el-divider>
              <pre class="code-block">{{ JSON.stringify(currentInterface.params || {}, null, 2) }}</pre>

              <el-divider>请求体</el-divider>
              <pre class="code-block">{{ JSON.stringify(currentInterface.body || {}, null, 2) }}</pre>
            </template>
          </el-dialog>
        </el-tab-pane>
        
        <el-tab-pane label="环境配置" name="environments">
          <el-table :data="environments" stripe>
            <el-table-column prop="env_code" label="环境代码" width="100">
              <template #default="{ row }">
                <el-tag :type="row.is_active ? 'success' : ''">{{ row.env_code }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="env_name" label="环境名称" />
            <el-table-column prop="base_url" label="基础URL" min-width="200" />
            <el-table-column prop="backend_lang" label="后端技术" width="100" />
            <el-table-column label="状态" width="80">
              <template #default="{ row }">
                <el-tag :type="row.is_active ? 'success' : 'info'" size="small">
                  {{ row.is_active ? '激活' : '禁用' }}
                </el-tag>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>
      </el-tabs>
    </el-drawer>

    <!-- 创建项目弹窗 -->
    <el-dialog v-model="dialogVisible" :title="isEdit ? '编辑项目' : '新建项目'" width="600px">
      <el-form :model="form" :rules="rules" ref="formRef" label-width="100px">
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="项目代码" prop="project_code">
              <el-input v-model="form.project_code" placeholder="如: API-TEST" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="项目名称" prop="project_name">
              <el-input v-model="form.project_name" placeholder="接口自动化测试平台" />
            </el-form-item>
          </el-col>
        </el-row>
        
        <el-form-item label="项目描述">
          <el-input v-model="form.description" type="textarea" :rows="2" />
        </el-form-item>
        
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="Git仓库">
              <el-input v-model="form.git_url" placeholder="https://github.com/..." />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="Jenkins Job">
              <el-input v-model="form.jenkins_job" placeholder="jenkins-job-name" />
            </el-form-item>
          </el-col>
        </el-row>
        
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="负责人">
              <el-input v-model="form.owner" placeholder="负责人姓名" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="状态">
              <el-switch v-model="form.is_active" active-text="启用" inactive-text="禁用" />
            </el-form-item>
          </el-col>
        </el-row>
      </el-form>
      
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSubmit" :loading="submitting">保存</el-button>
      </template>
    </el-dialog>

    <!-- 添加测试集到模块对话框 -->
    <el-dialog v-model="suiteDialogVisible" title="添加测试集" width="500px">
      <el-form :model="suiteForm" label-width="80px">
        <el-form-item label="名称" required>
          <el-input v-model="suiteForm.name" placeholder="测试集名称" />
        </el-form-item>
        <el-form-item label="描述">
          <el-input v-model="suiteForm.description" type="textarea" placeholder="测试集描述" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="suiteDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSaveSuite">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Delete, Setting, Link } from '@element-plus/icons-vue'
import axios from 'axios'

// API配置
const API_BASE_URL = ''

// 数据
const projects = ref<any[]>([])
const modules = ref<any[]>([])
const environments = ref<any[]>([])
const interfaces = ref<any[]>([])
const cases = ref<any[]>([])
const suites = ref<any[]>([])
const loading = ref(false)
const submitting = ref(false)
const dialogVisible = ref(false)
const detailVisible = ref(false)
const expandRowKeys = ref<string[]>([])
const suiteDialogVisible = ref(false)
const currentModuleId = ref<number | null>(null)
const suiteForm = reactive({ name: '', description: '' })
const isEdit = ref(false)
const activeTab = ref('info')
const currentProject = ref<any>(null)

// 模块相关
const moduleDialogVisible = ref(false)
const moduleForm = reactive({ module_code: '', module_name: '', level: 1 })
const isEditModule = ref(false)
const editingModuleId = ref<number | null>(null)

// 模块内容相关
const moduleTab = ref('interfaces')
const currentModule = ref<any>(null)
const moduleInterfaces = ref<any[]>([])
const moduleInterfacesLoading = ref(false)

// 添加接口到模块
const addModuleInterfaceDialogVisible = ref(false)
const availableInterfaces = ref<any[]>([])
const interfacesLoading = ref(false)
const selectedModuleInterfaces = ref<any[]>([])
const interfaceTableRef = ref()

// 接口详情
const interfaceDetailDialogVisible = ref(false)
const currentInterface = ref<any>(null)

// 获取模块关联的接口
const getModuleInterfaces = (moduleId: number) => {
  return interfaces.value.filter(i => i.module_id === moduleId)
}

const getMethodType = (method: string) => {
  const map: Record<string, any> = {
    'GET': 'success', 'POST': 'primary', 'PUT': 'warning', 'DELETE': 'danger', 'PATCH': 'info'
  }
  return map[method] || 'info'
}

// 选择模块
const selectModule = async (module: any) => {
  currentModule.value = module
  moduleTab.value = 'interfaces'
  await loadModuleInterfaces()
}

const loadModuleInterfaces = async () => {
  if (!currentModule.value) return
  moduleInterfacesLoading.value = true
  try {
    moduleInterfaces.value = getModuleInterfaces(currentModule.value.id)
  } finally {
    moduleInterfacesLoading.value = false
  }
}

// 显示添加接口对话框
const showAddInterfacesToModule = async () => {
  addModuleInterfaceDialogVisible.value = true
  interfacesLoading.value = true
  selectedModuleInterfaces.value = []
  try {
    // 加载所有接口
    const token = localStorage.getItem('token')
    const res = await axios.get(`/api/interfaces/?project_id=${currentProject.value?.id || 1}`, {
      headers: { Authorization: `Bearer ${token}` }
    })
    availableInterfaces.value = res.data?.items || res.data || []
  } catch (e: any) {
    ElMessage.error('加载接口失败')
    availableInterfaces.value = []
  } finally {
    interfacesLoading.value = false
  }
}

const handleModuleInterfaceSelection = (selection: any[]) => {
  selectedModuleInterfaces.value = selection
}

const saveModuleInterfaces = async () => {
  if (!currentModule.value || !selectedModuleInterfaces.value.length) return
  
  try {
    const token = localStorage.getItem('token')
    // 批量更新接口的 module_id
    for (const iface of selectedModuleInterfaces.value) {
      await axios.put(`/api/interfaces/${iface.id}`, {
        module_id: currentModule.value.id
      }, {
        headers: { Authorization: `Bearer ${token}` }
      })
    }
    ElMessage.success(`已添加 ${selectedModuleInterfaces.value.length} 个接口到模块`)
    addModuleInterfaceDialogVisible.value = false
    // 刷新接口列表
    await loadProjectDetail(currentProject.value)
    await loadModuleInterfaces()
  } catch (e: any) {
    ElMessage.error(`添加失败: ${e.message}`)
  }
}

const removeInterfaceFromModule = async (interfaceId: number) => {
  try {
    const token = localStorage.getItem('token')
    await axios.put(`/api/interfaces/${interfaceId}`, {
      module_id: null
    }, {
      headers: { Authorization: `Bearer ${token}` }
    })
    ElMessage.success('已移除')
    await loadModuleInterfaces()
    await loadProjectDetail(currentProject.value)
  } catch (e: any) {
    ElMessage.error(`移除失败: ${e.message}`)
  }
}

// 查看接口详情
const viewInterfaceDetail = (row: any) => {
  currentInterface.value = row
  interfaceDetailDialogVisible.value = true
}

const form = reactive({
  project_code: '',
  project_name: '',
  description: '',
  git_url: '',
  jenkins_job: '',
  owner: '',
  is_active: true
})

const rules = {
  project_code: [{ required: true, message: '请输入项目代码', trigger: 'blur' }],
  project_name: [{ required: true, message: '请输入项目名称', trigger: 'blur' }]
}

const formRef = ref()

// 加载项目列表
const loadProjects = async () => {
  loading.value = true
  try {
    const token = localStorage.getItem('token')
    const response = await axios.get(`${API_BASE_URL}/api/projects/`, {
      headers: { Authorization: `Bearer ${token}` }
    })
    projects.value = response.data
  } catch (error: any) {
    ElMessage.error(error.response?.data?.detail || '加载失败')
  } finally {
    loading.value = false
  }
}

// 加载项目详情
const loadProjectDetail = async (project: any) => {
  const token = localStorage.getItem('token')
  
  // 加载模块
  const modulesRes = await axios.get(`/api/projects/${project.id}/modules`, {
    headers: { Authorization: `Bearer ${token}` }
  })
  modules.value = modulesRes.data
  
  // 加载环境
  const envRes = await axios.get(`/api/environments/?project_id=${project.id}`, {
    headers: { Authorization: `Bearer ${token}` }
  })
  environments.value = envRes.data
  
  // 加载接口
  const interfacesRes = await axios.get(`/api/interfaces/?project_id=${project.id}`, {
    headers: { Authorization: `Bearer ${token}` }
  })
  interfaces.value = interfacesRes.data?.items || interfacesRes.data || []
  
  // 加载用例
  const casesRes = await axios.get(`/api/cases/?project_id=${project.id}`, {
    headers: { Authorization: `Bearer ${token}` }
  })
  cases.value = casesRes.data?.items || casesRes.data || []
  
  // 加载测试集
  const suitesRes = await axios.get(`/api/test-suites/?project_id=${project.id}`, {
    headers: { Authorization: `Bearer ${token}` }
  })
  suites.value = suitesRes.data || []
}

// 添加测试集到模块
const handleAddSuiteToModule = (moduleId: number) => {
  currentModuleId.value = moduleId
  suiteForm.name = ''
  suiteForm.description = ''
  suiteDialogVisible.value = true
}

const handleSaveSuite = async () => {
  if (!suiteForm.name.trim()) {
    ElMessage.warning('请输入测试集名称')
    return
  }
  if (!currentModuleId.value) return
  
  try {
    const token = localStorage.getItem('token')
    await axios.post('/api/test-suites/', {
      project_id: currentProject.value?.id || 1,
      module_id: currentModuleId.value,
      name: suiteForm.name,
      description: suiteForm.description
    }, {
      headers: { Authorization: `Bearer ${token}` }
    })
    ElMessage.success('测试集创建成功')
    suiteDialogVisible.value = false
    // 重新加载测试集
    const suitesRes = await axios.get(`/api/test-suites/?project_id=${currentProject.value?.id || 1}`, {
      headers: { Authorization: `Bearer ${token}` }
    })
    suites.value = suitesRes.data || []
  } catch (e: any) {
    ElMessage.error(`创建失败: ${e.message}`)
  }
}

// 打开模块测试集
const openModuleSuites = async (row: any) => {
  currentModule.value = row
  moduleSuiteDialogVisible.value = true
  await loadModuleSuites()
}

const loadModuleSuites = async () => {
  if (!currentModule.value) return
  moduleSuitesLoading.value = true
  try {
    const token = localStorage.getItem('token')
    // 获取该模块下的测试集
    const res = await axios.get(`/api/test-suites/?project_id=${currentProject.value?.id || 1}`, {
      headers: { Authorization: `Bearer ${token}` }
    })
    moduleSuites.value = (res.data || []).filter((s: any) => s.module_id === currentModule.value.id)
  } catch (e: any) {
    ElMessage.error(`加载失败: ${e.message}`)
    moduleSuites.value = []
  } finally {
    moduleSuitesLoading.value = false
  }
}

const handleRemoveSuiteFromModule = async (suiteId: number) => {
  try {
    const token = localStorage.getItem('token')
    await axios.put(`/api/test-suites/${suiteId}`, { module_id: null }, {
      headers: { Authorization: `Bearer ${token}` }
    })
    ElMessage.success('已移除')
    await loadModuleSuites()
    await loadProjectDetail(currentProject.value)
  } catch (e: any) {
    ElMessage.error(`移除失败: ${e.message}`)
  }
}

const goToExecute = (suiteId: number) => {
  // 跳转到接口执行页面
  window.location.href = `/interfaces/execute?suite=${suiteId}`
}

// 创建模块
const handleCreateModule = () => {
  isEditModule.value = false
  editingModuleId.value = null
  moduleForm.module_code = ''
  moduleForm.module_name = ''
  moduleForm.level = 1
  moduleDialogVisible.value = true
}

const handleEditModule = (row: any) => {
  isEditModule.value = true
  editingModuleId.value = row.id
  moduleForm.module_code = row.module_code
  moduleForm.module_name = row.module_name
  moduleForm.level = row.level
  moduleDialogVisible.value = true
}

const handleSaveModule = async () => {
  if (!moduleForm.module_code || !moduleForm.module_name) {
    ElMessage.warning('请填写模块代码和名称')
    return
  }
  try {
    const token = localStorage.getItem('token')
    if (isEditModule.value) {
      await axios.put(`/api/projects/${currentProject.value?.id}/modules/${editingModuleId.value}`, {
        module_code: moduleForm.module_code,
        module_name: moduleForm.module_name,
        level: moduleForm.level
      }, {
        headers: { Authorization: `Bearer ${token}` }
      })
      ElMessage.success('已更新')
    } else {
      await axios.post(`/api/projects/${currentProject.value?.id}/modules`, {
        module_code: moduleForm.module_code,
        module_name: moduleForm.module_name,
        level: moduleForm.level
      }, {
        headers: { Authorization: `Bearer ${token}` }
      })
      ElMessage.success('已创建')
    }
    moduleDialogVisible.value = false
    await loadProjectDetail(currentProject.value)
  } catch (e: any) {
    ElMessage.error(`失败: ${e.message}`)
  }
}

const handleDeleteModule = async (moduleId: number) => {
  try {
    const token = localStorage.getItem('token')
    await axios.delete(`/api/projects/${currentProject.value?.id}/modules/${moduleId}`, {
      headers: { Authorization: `Bearer ${token}` }
    })
    ElMessage.success('已删除')
    await loadProjectDetail(currentProject.value)
  } catch (e: any) {
    ElMessage.error(`删除失败: ${e.message}`)
  }
}

// 创建项目
const handleCreate = () => {
  isEdit.value = false
  Object.assign(form, {
    project_code: '',
    project_name: '',
    description: '',
    git_url: '',
    jenkins_job: '',
    owner: '',
    is_active: true
  })
  dialogVisible.value = true
}

// 提交表单
const handleSubmit = async () => {
  await formRef.value?.validate()
  submitting.value = true
  
  try {
    const token = localStorage.getItem('token')
    const data = { ...form, owner_id: 1 }
    
    if (isEdit.value) {
      await axios.put(`${API_BASE_URL}/api/projects/${currentProject.value?.id}`, data, {
        headers: { Authorization: `Bearer ${token}` }
      })
      ElMessage.success('保存成功')
    } else {
      await axios.post(`${API_BASE_URL}/api/projects/`, data, {
        headers: { Authorization: `Bearer ${token}` }
      })
      ElMessage.success('创建成功')
    }
    
    dialogVisible.value = false
    loadProjects()
  } catch (error: any) {
    ElMessage.error(error.response?.data?.detail || '操作失败')
  } finally {
    submitting.value = false
  }
}

// 查看详情
const handleDetail = async (project: any) => {
  currentProject.value = project
  activeTab.value = 'info'
  await loadProjectDetail(project)
  detailVisible.value = true
}

// 删除项目
const handleDelete = async (project: any) => {
  try {
    await ElMessageBox.confirm(`确定删除项目 "${project.project_name}" 吗?`, '提示', {
      type: 'warning'
    })
    
    const token = localStorage.getItem('token')
    await axios.delete(`${API_BASE_URL}/api/projects/${project.id}`, {
      headers: { Authorization: `Bearer ${token}` }
    })
    ElMessage.success('删除成功')
    loadProjects()
  } catch (error) {
    // 用户取消
  }
}

// 格式化日期
const formatDate = (date: string) => {
  return new Date(date).toLocaleDateString('zh-CN')
}

onMounted(() => {
  loadProjects()
})
</script>

<style scoped>
.project-management {
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

.project-card {
  margin-top: 20px;
}

.project-name {
  font-weight: 500;
}

.git-link {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  color: #409eff;
  text-decoration: none;
}

.git-link:hover {
  text-decoration: underline;
}

.text-muted {
  color: #909399;
}

.module-header,
.env-header {
  margin-bottom: 16px;
}

.module-detail {
  padding: 12px;
  background: #fafafa;
}

.module-children .child-card {
  background: #fff;
  border-radius: 4px;
}

.empty-text {
  color: #909399;
  font-size: 12px;
  text-align: center;
  padding: 20px;
}

/* 模块布局 */
.module-layout {
  display: flex;
  height: 500px;
  border: 1px solid #dcdfe6;
  border-radius: 4px;
}

.module-sidebar {
  width: 220px;
  border-right: 1px solid #dcdfe6;
  background: #fafafa;
}

.sidebar-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 16px;
  border-bottom: 1px solid #dcdfe6;
  font-weight: 500;
}

.module-item {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 16px;
  cursor: pointer;
  transition: background 0.2s;
}

.module-item:hover {
  background: #ecf5ff;
}

.module-item.active {
  background: #409eff;
  color: #fff;
}

.module-item .module-name {
  flex: 1;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.empty-module {
  padding: 40px 16px;
  text-align: center;
  color: #909399;
}

.module-content {
  flex: 1;
  padding: 16px;
  overflow: auto;
}

.content-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

.content-header h3 {
  margin: 0;
  display: flex;
  align-items: center;
  gap: 8px;
}

.code-block {
  background: #f5f5f5;
  padding: 12px;
  border-radius: 4px;
  font-size: 12px;
  max-height: 200px;
  overflow: auto;
}

.text-muted {
  color: #909399;
}
</style>
