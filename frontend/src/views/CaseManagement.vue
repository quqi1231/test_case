<template>
  <div class="case-management">
    <!-- 顶部导航 -->
    <div class="header">
      <h1>🧪 测试用例管理</h1>
      <div class="header-actions">
        <el-input
          v-model="searchText"
          placeholder="搜索用例编号/标题"
          style="width: 200px"
          clearable
          @keyup.enter="loadData"
          @clear="loadData"
        />
        <el-select v-model="filterPriority" placeholder="优先级" style="width: 120px; margin-left: 12px" clearable @change="loadData">
          <el-option label="P0" value="P0" />
          <el-option label="P1" value="P1" />
          <el-option label="P2" value="P2" />
          <el-option label="P3" value="P3" />
        </el-select>
        <el-select v-model="filterStatus" placeholder="状态" style="width: 120px; margin-left: 12px" clearable @change="loadData">
          <el-option label="草稿" value="draft" />
          <el-option label="就绪" value="ready" />
          <el-option label="通过" value="passed" />
          <el-option label="失败" value="failed" />
          <el-option label="禁用" value="disabled" />
        </el-select>
        <el-button type="primary" @click="handleCreate" style="margin-left: 12px">
          <el-icon><Plus /></el-icon>新建用例
        </el-button>
      </div>
    </div>

    <!-- 用例列表 -->
    <el-card class="case-card">
      <el-table :data="cases" v-loading="loading" stripe>
        <el-table-column prop="case_code" label="用例编号" width="120">
          <template #default="{ row }">
            <el-tag>{{ row.case_code }}</el-tag>
          </template>
        </el-table-column>
        
        <el-table-column prop="case_title" label="用例标题" min-width="180" />
        
        <el-table-column prop="case_type" label="类型" width="80">
          <template #default="{ row }">
            <el-tag :type="row.case_type === 'scene' ? 'warning' : 'primary'">
              {{ row.case_type === 'scene' ? '场景' : '单接口' }}
            </el-tag>
          </template>
        </el-table-column>
        
        <el-table-column prop="priority" label="优先级" width="80">
          <template #default="{ row }">
            <el-tag :type="getPriorityType(row.priority)">{{ row.priority }}</el-tag>
          </template>
        </el-table-column>
        
        <el-table-column prop="pre_condition" label="前置条件" width="100">
          <template #default="{ row }">
            <span v-if="row.pre_condition" class="text-line-2">{{ row.pre_condition }}</span>
            <span v-else class="text-muted">-</span>
          </template>
        </el-table-column>
        
        <el-table-column prop="test_steps" label="测试步骤" width="120">
          <template #default="{ row }">
            <span v-if="row.test_steps" class="text-line-2">{{ row.test_steps }}</span>
            <span v-else class="text-muted">-</span>
          </template>
        </el-table-column>
        
        <el-table-column prop="expected_result" label="预期结果" width="100">
          <template #default="{ row }">
            <span v-if="row.expected_result" class="text-line-2">{{ row.expected_result }}</span>
            <span v-else class="text-muted">-</span>
          </template>
        </el-table-column>
        
        <el-table-column prop="actual_result" label="实际结果" width="100">
          <template #default="{ row }">
            <span v-if="row.actual_result" class="text-line-2">{{ row.actual_result }}</span>
            <span v-else class="text-muted">-</span>
          </template>
        </el-table-column>
        
        <el-table-column prop="interface_id" label="关联接口" width="150">
          <template #default="{ row }">
            <span v-if="row.interface_id">{{ getInterfaceName(row.interface_id) }}</span>
            <span v-else class="text-muted">-</span>
          </template>
        </el-table-column>
        
        <el-table-column label="数据驱动" width="100">
          <template #default="{ row }">
            <el-tag v-if="row.data_source && row.data_source !== 'none'" type="success" size="small">
              {{ row.data_source }}
            </el-tag>
            <span v-else class="text-muted">无</span>
          </template>
        </el-table-column>
        
        <el-table-column label="状态" width="80">
          <template #default="{ row }">
            <el-tag :type="getStatusType(row.status)">{{ getStatusText(row.status) }}</el-tag>
          </template>
        </el-table-column>
        
        <el-table-column label="操作" width="150" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" link @click="handleEdit(row)">编辑</el-button>
            <el-button type="danger" link @click="handleDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 编辑弹窗 -->
    <el-dialog v-model="dialogVisible" title="用例详情" width="800px">
      <el-tabs v-model="activeTab">
        <!-- 基本信息 -->
        <el-tab-pane label="基本信息" name="basic">
          <el-form :model="form" label-width="100px">
            <el-row :gutter="20">
              <el-col :span="12">
                <el-form-item label="用例编号">
                  <el-input v-model="form.case_code" placeholder="TC-USER-001" />
                </el-form-item>
              </el-col>
              <el-col :span="12">
                <el-form-item label="用例标题">
                  <el-input v-model="form.case_title" />
                </el-form-item>
              </el-col>
            </el-row>
            
            <el-row :gutter="20">
              <el-col :span="8">
                <el-form-item label="用例类型">
                  <el-select v-model="form.case_type" style="width: 100%">
                    <el-option label="单接口" value="single" />
                    <el-option label="场景" value="scene" />
                  </el-select>
                </el-form-item>
              </el-col>
              <el-col :span="8">
                <el-form-item label="优先级">
                  <el-select v-model="form.priority" style="width: 100%">
                    <el-option label="P0-紧急" value="P0" />
                    <el-option label="P1-高" value="P1" />
                    <el-option label="P2-中" value="P2" />
                    <el-option label="P3-低" value="P3" />
                  </el-select>
                </el-form-item>
              </el-col>
              <el-col :span="8">
                <el-form-item label="状态">
                  <el-select v-model="form.status" style="width: 100%">
                    <el-option label="草稿" value="draft" />
                    <el-option label="就绪" value="ready" />
                    <el-option label="运行中" value="running" />
                    <el-option label="通过" value="passed" />
                    <el-option label="失败" value="failed" />
                  </el-select>
                </el-form-item>
              </el-col>
            </el-row>
            
            <el-form-item label="用例描述">
              <el-input v-model="form.description" type="textarea" :rows="2" />
            </el-form-item>
            
            <el-form-item label="前置条件">
              <el-input v-model="form.pre_condition" type="textarea" :rows="2" placeholder="执行测试前的准备工作" />
            </el-form-item>
            
            <el-form-item label="测试步骤">
              <el-input v-model="form.test_steps" type="textarea" :rows="3" placeholder="1. 登录系统&#10;2. 进入用户管理..." />
            </el-form-item>
            
            <el-row :gutter="20">
              <el-col :span="12">
                <el-form-item label="测试数据">
                  <el-input v-model="form.test_data" type="textarea" :rows="3" placeholder="username: admin&#10;password: 123456" />
                </el-form-item>
              </el-col>
              <el-col :span="12">
                <el-form-item label="预期结果">
                  <el-input v-model="form.expected_result" type="textarea" :rows="3" placeholder="返回状态码200，登录成功" />
                </el-form-item>
              </el-col>
            </el-row>
            
            <el-form-item label="实际结果">
              <el-input v-model="form.actual_result" type="textarea" :rows="2" placeholder="测试执行后填充" />
            </el-form-item>
            
            <el-form-item label="备注">
              <el-input v-model="form.remark" type="textarea" :rows="2" placeholder="其他说明..." />
            </el-form-item>
            
            <el-row :gutter="20">
              <el-col :span="8">
                <el-form-item label="标签">
                  <el-input v-model="form.tags" placeholder="smoke,regression" />
                </el-form-item>
              </el-col>
              <el-col :span="8">
                <el-form-item label="超时(秒)">
                  <el-input-number v-model="form.timeout" :min="1" :max="300" />
                </el-form-item>
              </el-col>
              <el-col :span="8">
                <el-form-item label="重试次数">
                  <el-input-number v-model="form.retry_times" :min="0" :max="5" />
                </el-form-item>
              </el-col>
            </el-row>
          </el-form>
        </el-tab-pane>
        
        <!-- 接口关联 -->
        <el-tab-pane label="接口关联" name="interface">
          <el-form label-width="100px">
            <el-form-item label="关联接口">
              <el-select v-model="form.interface_id" placeholder="选择接口" style="width: 100%" filterable>
                <el-option 
                  v-for="iface in interfaces" 
                  :key="iface.id" 
                  :label="`${iface.method} ${iface.path} - ${iface.api_name}`" 
                  :value="iface.id" 
                />
              </el-select>
            </el-form-item>
          </el-form>
          
          <div v-if="form.interface_id" class="interface-preview">
            <el-descriptions :column="2" border size="small">
              <el-descriptions-item label="接口代码">
                {{ selectedInterface?.api_code }}
              </el-descriptions-item>
              <el-descriptions-item label="请求方法">
                <el-tag>{{ selectedInterface?.method }}</el-tag>
              </el-descriptions-item>
              <el-descriptions-item label="接口路径" :span="2">
                {{ selectedInterface?.path }}
              </el-descriptions-item>
              <el-descriptions-item label="请求示例" :span="2">
                <pre>{{ selectedInterface?.request_example || '无' }}</pre>
              </el-descriptions-item>
            </el-descriptions>
          </div>
        </el-tab-pane>
        
        <!-- 参数化配置 -->
        <el-tab-pane label="参数化配置" name="params">
          <div class="params-header">
            <el-radio-group v-model="form.data_source">
              <el-radio label="none">无</el-radio>
              <el-radio label="json">JSON</el-radio>
              <el-radio label="excel">Excel</el-radio>
              <el-radio label="yaml">YAML</el-radio>
              <el-radio label="code">代码</el-radio>
            </el-radio-group>
          </div>
          
          <div v-if="form.data_source && form.data_source !== 'none'" class="params-content">
            <el-form-item label="数据文件" v-if="form.data_source !== 'code'">
              <el-input v-model="form.data_file" placeholder="数据文件路径" />
            </el-form-item>
            
            <el-form-item label="Sheet名称" v-if="form.data_source === 'excel'">
              <el-input v-model="form.data_sheet" placeholder="Sheet1" />
            </el-form-item>
            
            <el-form-item label="参数数据" v-if="form.data_source === 'json'">
              <el-input v-model="form.params_json" type="textarea" :rows="10" placeholder='[{"username": "admin", "password": "123456"}]' />
            </el-form-item>
          </div>
        </el-tab-pane>
        
        <!-- 断言配置 -->
        <el-tab-pane label="断言配置" name="assertions">
          <el-form-item label="断言规则">
            <el-input v-model="form.assertions" type="textarea" :rows="8" placeholder='[{"type": "status", "expected": 200}, {"type": "jsonpath", "rule": "$.code", "expected": 0}]' />
          </el-form-item>
          <el-divider />
          <div class="assertion-tips">
            <p><strong>支持的断言类型：</strong></p>
            <ul>
              <li>status - HTTP状态码</li>
              <li>jsonpath - JSON路径断言</li>
              <li>contains - 包含字符串</li>
              <li>regex - 正则匹配</li>
              <li>response_time - 响应时间(毫秒)</li>
            </ul>
          </div>
        </el-tab-pane>
        
        <!-- 前后置脚本 -->
        <el-tab-pane label="前后置脚本" name="scripts">
          <el-form-item label="前置脚本">
            <el-input v-model="form.setup_script" type="textarea" :rows="4" placeholder="# 执行前的准备代码&#10;print('Setup...')" />
          </el-form-item>
          
          <el-form-item label="后置脚本">
            <el-input v-model="form.teardown_script" type="textarea" :rows="4" placeholder="# 执行后的清理代码&#10;print('Teardown...')" />
          </el-form-item>
        </el-tab-pane>
      </el-tabs>
      
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSave">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import axios from 'axios'

// 数据
const cases = ref<any[]>([])
const interfaces = ref<any[]>([])
const modules = ref<any[]>([])
const loading = ref(false)
const searchText = ref('')
const filterPriority = ref('')
const filterStatus = ref('')
const dialogVisible = ref(false)
const activeTab = ref('basic')
const editingId = ref<number | null>(null)

const form = reactive({
  project_id: 1,
  module_id: null as number | null,
  case_code: '',
  case_title: '',
  case_type: 'single',
  priority: 'P1',
  status: 'draft',
  interface_id: null as number | null,
  description: '',
  pre_condition: '',
  test_steps: '',
  test_data: '',
  expected_result: '',
  actual_result: '',
  remark: '',
  tags: '',
  timeout: 30,
  retry_times: 0,
  data_source: 'none',
  data_file: '',
  data_sheet: '',
  params_json: '',
  assertions: '',
  setup_script: '',
  teardown_script: ''
})

// 计算选中的接口
const selectedInterface = computed(() => {
  return interfaces.value.find(i => i.id === form.interface_id)
})

// 获取接口名称
const getInterfaceName = (interfaceId: number) => {
  const iface = interfaces.value.find(i => i.id === interfaceId)
  return iface ? `${iface.method} ${iface.path}` : '-'
}

const getModuleName = (moduleId: number) => {
  const m = modules.value.find(m => m.id === moduleId)
  return m?.module_name || '-'
}

// 优先级颜色
const getPriorityType = (priority: string) => {
  const map: Record<string, string> = { P0: 'danger', P1: 'warning', P2: 'primary', P3: 'info' }
  return map[priority] || 'info'
}

// 状态颜色和文本
const getStatusType = (status: string) => {
  const map: Record<string, string> = { draft: 'info', ready: 'primary', running: 'warning', passed: 'success', failed: 'danger', disabled: 'info' }
  return map[status] || 'info'
}

const getStatusText = (status: string) => {
  const map: Record<string, string> = { draft: '草稿', ready: '就绪', running: '运行中', passed: '通过', failed: '失败', disabled: '禁用' }
  return map[status] || status
}

// 加载数据
const loadData = async () => {
  loading.value = true
  try {
    // 加载用例
    const casesRes = await axios.get('/api/cases/?project_id=1')
    let allCases = casesRes.data?.items || casesRes.data || []
    
    // 前端搜索过滤
    if (searchText.value || filterPriority.value || filterStatus.value) {
      const keyword = searchText.value.toLowerCase()
      allCases = allCases.filter((c: any) => {
        const matchKeyword = !keyword || 
          c.case_code?.toLowerCase().includes(keyword) || 
          c.case_title?.toLowerCase().includes(keyword)
        const matchPriority = !filterPriority.value || c.priority === filterPriority.value
        const matchStatus = !filterStatus.value || c.status === filterStatus.value
        return matchKeyword && matchPriority && matchStatus
      })
    }
    cases.value = allCases
    
    // 加载接口
    const interfacesRes = await axios.get('/api/interfaces/?project_id=1')
    interfaces.value = interfacesRes.data?.items || interfacesRes.data || []
    
    // 加载模块
    const modulesRes = await axios.get('/api/projects/1/modules')
    modules.value = modulesRes.data || []
  } catch (error: any) {
    ElMessage.error(error.response?.data?.detail || '加载失败')
  } finally {
    loading.value = false
  }
}

// 编辑
const handleEdit = (row: any) => {
  editingId.value = row.id
  Object.assign(form, row)
  dialogVisible.value = true
}

// 保存
const handleSave = async () => {
  try {
    const data = { ...form }
    if (editingId.value) {
      await axios.put(`/api/cases/${editingId.value}`, data)
    } else {
      await axios.post('/api/cases/', data)
    }
    ElMessage.success('保存成功')
    dialogVisible.value = false
    loadData()
  } catch (error: any) {
    ElMessage.error(error.response?.data?.detail || '保存失败')
  }
}

// 删除
const handleDelete = async (row: any) => {
  try {
    await ElMessageBox.confirm(`确定删除用例 "${row.case_title}" 吗?`, '提示', { type: 'warning' })
    await axios.delete(`/api/cases/${row.id}`)
    ElMessage.success('删除成功')
    loadData()
  } catch (error) {
    // 用户取消
  }
}

onMounted(() => {
  loadData()
})
</script>

<style scoped>
.case-management {
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

.case-card {
  margin-top: 20px;
}

.text-muted {
  color: #909399;
}

.interface-preview {
  margin-top: 16px;
  padding: 12px;
  background: #f5f7fa;
  border-radius: 4px;
}

.interface-preview pre {
  margin: 0;
  white-space: pre-wrap;
  font-size: 12px;
}

.params-header {
  margin-bottom: 16px;
}

.params-content {
  margin-top: 16px;
}

.assertion-tips {
  padding: 12px;
  background: #f5f7fa;
  border-radius: 4px;
  font-size: 12px;
}

.assertion-tips ul {
  margin: 8px 0 0;
  padding-left: 20px;
}
</style>
