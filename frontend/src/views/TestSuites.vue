<template>
  <div class="test-suites">
    <div style="margin-bottom: 16px">
      <el-button type="primary" @click="handleCreate"><el-icon><Plus /></el-icon>新建测试集</el-button>
    </div>
    <el-table :data="suites" row-key="id" v-loading="loading" empty-text="暂无测试集">
      <el-table-column prop="name" label="名称" />
      <el-table-column prop="description" label="描述" />
      <el-table-column prop="module_name" label="所属模块" width="120">
        <template #default="{row}">
          <el-tag v-if="row.module_name" type="info">{{ row.module_name }}</el-tag>
          <span v-else class="text-muted">-</span>
        </template>
      </el-table-column>
      <el-table-column prop="item_count" label="接口数" width="80">
        <template #default="{row}"><el-tag type="success">{{ row.item_count || 0 }}</el-tag></template>
      </el-table-column>
      <el-table-column label="执行结果" width="120">
        <template #default="{row}">
          <template v-if="row.last_status">
            <el-tag :type="row.last_status === 'success' ? 'success' : 'danger'">
              {{ row.last_success }}/{{ row.last_total }}
            </el-tag>
          </template>
          <span v-else class="text-muted">未执行</span>
        </template>
      </el-table-column>
      <el-table-column label="耗时" width="80">
        <template #default="{row}">
          <span v-if="row.last_duration">{{ row.last_duration }}ms</span>
          <span v-else class="text-muted">-</span>
        </template>
      </el-table-column>
      <el-table-column label="最后运行" width="160">
        <template #default="{row}">
          <span v-if="row.last_run_at">{{ formatTime(row.last_run_at) }}</span>
          <span v-else class="text-muted">-</span>
        </template>
      </el-table-column>
      <el-table-column prop="created_at" label="创建时间" width="160" />
      <el-table-column label="操作" width="300">
        <template #default="{row}">
          <el-button type="primary" link @click="handleViewDetail(row)">详情</el-button>
          <el-button type="primary" link @click="handleManageItems(row)">接口</el-button>
          <el-button type="primary" link @click="handleExecute(row)">执行</el-button>
          <el-button type="primary" link @click="handleEdit(row)">编辑</el-button>
          <el-popconfirm title="确认删除?" @confirm="handleDelete(row.id)">
            <template #reference><el-button type="danger" link>删除</el-button></template>
          </el-popconfirm>
        </template>
      </el-table-column>
    </el-table>

    <!-- 新建/编辑测试集对话框 -->
    <el-dialog v-model="dialogVisible" :title="editingId?'编辑测试集':'新建测试集'" width="500px">
      <el-form :model="form" label-width="80px">
        <el-form-item label="名称" required><el-input v-model="form.name" placeholder="测试集名称" /></el-form-item>
        <el-form-item label="模块">
          <el-select v-model="form.module_id" placeholder="选择模块" clearable>
            <el-option v-for="m in modules" :key="m.id" :label="m.module_name" :value="m.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="描述"><el-input v-model="form.description" type="textarea" /></el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible=false">取消</el-button>
        <el-button type="primary" @click="handleSave">保存</el-button>
      </template>
    </el-dialog>

    <!-- 测试集详情对话框 -->
    <el-dialog v-model="detailDialogVisible" :title="`${currentSuite?.name} - 详情`" width="1000px">
      <el-tabs v-model="detailTab">
        <el-tab-pane label="接口列表" name="interfaces">
          <div style="margin-bottom: 12px">
            <el-button type="primary" size="small" @click="showAddInterfaceDialog">
              <el-icon><Plus /></el-icon>添加接口
            </el-button>
          </div>
          <el-table :data="suiteInterfaces" v-loading="detailLoading">
            <el-table-column prop="order_index" label="顺序" width="60" />
            <el-table-column prop="name" label="接口名称" />
            <el-table-column prop="method" label="方法" width="80">
              <template #default="{row}">
                <el-tag :type="getMethodType(row.method)">{{ row.method }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="url" label="URL" show-overflow-tooltip />
            <el-table-column label="变量提取" width="120">
              <template #default="{row}">
                <el-button type="primary" link size="small" @click="openVarExtractConfig(row)">
                  {{ row.var_extracts ? '已配置' : '配置' }}
                </el-button>
              </template>
            </el-table-column>
            <el-table-column label="操作" width="100">
              <template #default="{row, $index}">
                <el-button type="danger" link size="small" @click="removeItem(row.id, $index)">移除</el-button>
              </template>
            </el-table-column>
          </el-table>
          <el-empty v-if="!suiteInterfaces.length" description="暂无接口，请添加" />
        </el-tab-pane>
        
        <el-tab-pane label="参数化配置" name="params">
          <div class="param-config">
            <div style="margin-bottom: 16px;display:flex;justify-content:space-between">
              <div>
                <el-button type="primary" size="small" @click="showImportDataDialog">
                  <el-icon><Upload /></el-icon>导入测试数据
                </el-button>
                <el-button size="small" @click="showAddParamRow">添加参数</el-button>
              </div>
              <el-tag>共 {{ paramData.length }} 组数据</el-tag>
            </div>
            
            <el-table :data="paramData" border>
              <el-table-column label="#" width="50">
                <template #default="{$index}">{{ $index + 1 }}</template>
              </el-table-column>
              <el-table-column v-for="col in paramColumns" :key="col" :prop="col" :label="col">
                <template #default="{row}">
                  <el-input v-model="row[col]" size="small" />
                </template>
              </el-table-column>
              <el-table-column label="操作" width="60">
                <template #default="{row, $index}">
                  <el-button type="danger" link size="small" @click="paramData.splice($index,1)">删除</el-button>
                </template>
              </el-table-column>
            </el-table>
            
            <div style="margin-top:16px">
              <el-button type="primary" @click="executeWithParams" :loading="executingParams">
                循环执行 ({{ paramData.length }}组)
              </el-button>
            </div>
          </div>
        </el-tab-pane>
        
        <el-tab-pane label="执行记录" name="results">
          <el-table :data="testResults" v-loading="resultsLoading">
            <el-table-column prop="id" label="ID" width="60" />
            <el-table-column label="状态" width="100">
              <template #default="{row}">
                <el-tag :type="row.status==='success' || row.passed===true ?'success':'danger'">
                  {{ row.status==='success' || row.passed===true ? '成功' : '失败' }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column label="结果" width="120">
              <template #default="{row}">
                <span v-if="row.success_count!==undefined">{{ row.success_count }}/{{ row.total_count }}</span>
                <span v-else>{{ row.passed!==undefined ? (row.passed?'通过':'失败') : '-' }}</span>
              </template>
            </el-table-column>
            <el-table-column prop="duration_ms" label="耗时" width="80">
              <template #default="{row}">{{ row.duration_ms }}ms</template>
            </el-table-column>
            <el-table-column prop="started_at" label="运行时间" width="180" />
            <el-table-column label="操作" width="150" fixed="right">
              <template #default="{row}">
                <el-button type="primary" link size="small" @click="viewResultDetail(row)">查看详情</el-button>
                <el-button type="danger" link size="small" @click="deleteResult(row.id)">删除</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>
      </el-tabs>
      <template #footer>
        <el-button @click="detailDialogVisible=false">关闭</el-button>
      </template>
    </el-dialog>

    <!-- 变量提取配置对话框 -->
    <el-dialog v-model="varExtractDialogVisible" title="变量提取配置" width="500px">
      <el-alert type="info" :closable="false" style="margin-bottom:16px">
        从响应中提取变量，供后续接口使用<br>
        支持：$.data.xxx (JSON路径), $resp.headers.xxx (响应头)
      </el-alert>
      <div v-for="(v,k) in currentVarExtracts" :key="k" style="display:flex;gap:8px;margin-bottom:8px">
        <el-input v-model="currentVarExtracts[k]" placeholder="变量名" style="width:150px" />
        <el-input v-model="currentVarExtracts[k]" placeholder="提取路径 $.data.token" style="flex:1" />
        <el-button type="danger" link @click="delete currentVarExtracts[k]">×</el-button>
      </div>
      <el-button size="small" @click="currentVarExtracts[Date.now()] = ''">+ 添加变量</el-button>
      <template #footer>
        <el-button @click="varExtractDialogVisible=false">取消</el-button>
        <el-button type="primary" @click="saveVarExtracts">保存</el-button>
      </template>
    </el-dialog>

    <!-- 导入测试数据对话框 -->
    <el-dialog v-model="importDataDialogVisible" title="导入测试数据" width="500px">
      <el-upload drag :auto-upload="false" :on-change="handleFileChange" accept=".xlsx,.xls,.csv,.json">
        <el-icon class="el-icon--upload"><Upload /></el-icon>
        <div class="el-upload__text">点击或拖拽上传文件</div>
        <template #tip>
          <div class="el-upload__tip">支持 Excel(.xlsx/.xls)、CSV、JSON 格式</div>
        </template>
      </el-upload>
      <div v-if="previewData.length" style="margin-top:16px">
        <el-divider>数据预览 (前3行)</el-divider>
        <el-table :data="previewData" size="small" max-height="200">
          <el-table-column v-for="col in paramColumns" :key="col" :prop="col" :label="col" />
        </el-table>
      </div>
      <template #footer>
        <el-button @click="importDataDialogVisible=false">取消</el-button>
        <el-button type="primary" @click="confirmImportData" :disabled="!previewData.length">确认导入</el-button>
      </template>
    </el-dialog>

    <!-- 执行结果详情对话框 -->
    <el-dialog v-model="resultDetailVisible" title="执行结果详情" width="800px">
      <div v-if="currentResultDetail">
        <div style="margin-bottom:16px">
          <el-tag :type="currentResultDetail.passed?'success':'danger'" size="large">
            {{ currentResultDetail.passed ? '✓ 通过' : '✗ 失败' }}
          </el-tag>
          <el-tag type="info" style="margin-left:8px">耗时：{{ currentResultDetail.duration_ms || currentResultDetail.elapsed_ms }}ms</el-tag>
        </div>
        
        <el-divider>接口执行详情</el-divider>
        <div v-if="currentResultDetail.results?.length">
          <el-card v-for="(r, idx) in currentResultDetail.results" :key="idx" :class="['result-item', r.passed?'success':'fail']" style="margin-bottom:12px">
            <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:8px">
              <div style="display:flex;align-items:center;gap:8px">
                <el-badge :value="idx+1" :type="r.passed?'success':'danger'" />
                <span style="font-weight:500">{{ r.name || `接口${idx+1}` }}</span>
                <el-tag :type="r.status_code<400?'success':'danger'">{{ r.status_code }}</el-tag>
                <el-tag type="info">{{ r.elapsed_ms }}ms</el-tag>
              </div>
              <el-button type="primary" link size="small" @click="r.showDetail = !r.showDetail">
                {{ r.showDetail ? '收起' : '详情' }}
              </el-button>
            </div>
            <div v-if="r.showDetail">
              <div style="margin-bottom:8px;font-size:13px">
                <strong>请求:</strong> {{ r.method }} {{ r.url }}
              </div>
              <div style="margin-bottom:8px;font-size:13px">
                <strong>提取变量:</strong> 
                <el-tag v-for="(v,k) in r.extracted_vars" :key="k" size="small" style="margin-right:4px">{{ k }}={{ v }}</el-tag>
                <span v-if="!r.extracted_vars || Object.keys(r.extracted_vars).length===0" style="color:#999">无</span>
              </div>
              <div style="margin-bottom:8px;font-size:13px">
                <strong>断言:</strong>
                <el-tag v-for="(a,i) in r.assertions" :key="i" :type="a.passed?'success':'danger'" size="small" style="margin-right:4px">
                  {{ a.type }}: {{ a.expected }} {{ a.passed?'✓':'✗' }}
                </el-tag>
                <span v-if="!r.assertions?.length" style="color:#999">无</span>
              </div>
              <div>
                <strong>响应体:</strong>
                <pre style="background:#1e1e1e;color:#d4d4d4;padding:12px;border-radius:4px;overflow:auto;max-height:300px;font-size:12px;margin-top:4px">{{ JSON.stringify(r.body||r.response,null,2) }}</pre>
              </div>
            </div>
          </el-card>
        </div>
        <div v-else>
          <pre style="background:#1e1e1e;color:#d4d4d4;padding:12px;border-radius:4px;overflow:auto;max-height:400px;font-size:12px">{{ JSON.stringify(currentResultDetail,null,2) }}</pre>
        </div>
      </div>
      <template #footer>
        <el-button @click="resultDetailVisible=false">关闭</el-button>
      </template>
    </el-dialog>

    <!-- 添加接口对话框 -->
    <el-dialog v-model="addInterfaceDialogVisible" title="添加接口" width="700px">
      <el-table :data="availableInterfaces" v-loading="interfacesLoading" @selection-change="handleSelectionChange" empty-text="暂无接口">
        <el-table-column type="selection" width="40" />
        <el-table-column prop="name" label="接口名称" />
        <el-table-column prop="method" label="方法" width="80">
          <template #default="{row}">
            <el-tag :type="getMethodType(row.method)">{{ row.method }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="url" label="URL" show-overflow-tooltip />
      </el-table>
      <template #footer>
        <el-button @click="addInterfaceDialogVisible=false">取消</el-button>
        <el-button type="primary" @click="handleAddInterfaces" :disabled="!selectedInterfaces.length">添加选中接口</el-button>
      </template>
    </el-dialog>

    <!-- 添加用例对话框 -->
    <el-dialog v-model="addCaseDialogVisible" title="添加用例" width="700px">
      <el-table :data="availableCases" v-loading="casesLoading" @selection-change="handleCaseSelectionChange" empty-text="暂无用例">
        <el-table-column type="selection" width="40" />
        <el-table-column prop="name" label="用例名称" />
        <el-table-column prop="priority" label="优先级" width="80">
          <template #default="{row}">
            <el-tag :type="getPriorityType(row.priority)">{{ row.priority }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="interface_name" label="关联接口" />
      </el-table>
      <template #footer>
        <el-button @click="addCaseDialogVisible=false">取消</el-button>
        <el-button type="primary" @click="handleAddCases" :disabled="!selectedCases.length">添加选中用例</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { Plus, Upload } from '@element-plus/icons-vue'
import axios from 'axios'

const props = defineProps<{projectId:number}>()

interface Suite { 
  id:number; name:string; description?:string; project_id:number; module_id?:number;
  module_name?:string; item_count?:number; case_count?:number; created_at?:string;
  last_status?:string; last_success?:number; last_total?:number; last_duration?:number; last_run_at?:string
}

interface SuiteItem {
  id: number
  order_index: number
  name: string
  method: string
  url: string
  interface_id?: number
}

const loading = ref(false)
const suites = ref<Suite[]>([])
const modules = ref<any[]>([])
const dialogVisible = ref(false)
const editingId = ref<number|null>(null)
const form = reactive({name:'', description:'', module_id: null as number|null})

// 详情对话框
const detailDialogVisible = ref(false)
const currentSuite = ref<Suite | null>(null)
const detailTab = ref('interfaces')
const detailLoading = ref(false)
const suiteInterfaces = ref<SuiteItem[]>([])
const suiteCases = ref<any[]>([])
const casesLoading = ref(false)

// 添加接口
const addInterfaceDialogVisible = ref(false)
const interfacesLoading = ref(false)
const availableInterfaces = ref<any[]>([])
const selectedInterfaces = ref<any[]>([])

// 添加用例
const addCaseDialogVisible = ref(false)
const availableCases = ref<any[]>([])
const selectedCases = ref<any[]>([])

const getMethodType = (method: string) => {
  const map: Record<string, any> = {
    'GET': 'success', 'POST': 'primary', 'PUT': 'warning', 'DELETE': 'danger', 'PATCH': 'info'
  }
  return map[method] || 'info'
}

const formatTime = (time: string) => {
  if (!time) return '-'
  const d = new Date(time)
  return d.toLocaleString('zh-CN', { 
    month: '2-digit', 
    day: '2-digit', 
    hour: '2-digit', 
    minute: '2-digit',
    second: '2-digit'
  })
}

const getPriorityType = (priority: string) => {
  const map: Record<string, any> = { 'P0': 'danger', 'P1': 'warning', 'P2': 'primary', 'P3': 'info' }
  return map[priority] || 'info'
}

const loadSuites = async () => {
  loading.value = true
  try{
    const token = localStorage.getItem('token')
    const res = await axios.get(`/api/test-suites/?project_id=${props.projectId}`,{headers:{Authorization:`Bearer ${token}`}})
    suites.value = Array.isArray(res.data) ? res.data : []
  }catch{suites.value=[]}
  finally{loading.value=false}
}

const loadModules = async () => {
  try {
    const token = localStorage.getItem('token')
    const res = await axios.get(`/api/projects/${props.projectId}/modules`, {
      headers: { Authorization: `Bearer ${token}` }
    })
    modules.value = res.data || []
  } catch {
    modules.value = []
  }
}

const handleCreate = () => {
  editingId.value = null
  form.name = ''
  form.description = ''
  form.module_id = null
  dialogVisible.value = true
}

const handleEdit = (row:Suite) => {
  editingId.value = row.id
  form.name = row.name
  form.description = row.description || ''
  form.module_id = row.module_id || null
  dialogVisible.value = true
}

const handleSave = async () => {
  if(!form.name){ElMessage.warning('请输入名称');return}
  try{
    const token = localStorage.getItem('token')
    const projectId = props.projectId || 1
    const data = {
      name: form.name,
      description: form.description,
      module_id: form.module_id || null,
      project_id: projectId
    }
    if(editingId.value){
      await axios.put(`/api/test-suites/${editingId.value}`,data,{headers:{Authorization:`Bearer ${token}`}})
      ElMessage.success('已更新')
    }else{
      await axios.post('/api/test-suites/',data,{headers:{Authorization:`Bearer ${token}`}})
      ElMessage.success('已创建')
    }
    dialogVisible.value=false;loadSuites()
  }catch(e:any){ElMessage.error(`失败: ${e.response?.data?.detail || e.message}`)}
}

const handleDelete = async (id:number) => {
  try{const token=localStorage.getItem('token');await axios.delete(`/api/test-suites/${id}`,{headers:{Authorization:`Bearer ${token}`}});ElMessage.success('已删除');loadSuites()}catch(e:any){ElMessage.error(`删除失败: ${e.response?.data?.detail || e.message}`)}
}

const handleExecute = async (row:Suite) => {
  try{const token=localStorage.getItem('token');const res=await axios.post(`/api/test-suites/${row.id}/execute`,{},{headers:{Authorization:`Bearer ${token}`}});ElMessage.success(`执行完成: ${res.data.success || res.data.passed}/${res.data.total}通过`);loadSuites()}catch(e:any){ElMessage.error(`执行失败: ${e.response?.data?.detail || e.message}`)}
}

// 查看详情
const handleViewDetail = async (row: Suite) => {
  currentSuite.value = row
  detailDialogVisible.value = true
  detailTab.value = 'interfaces'
  await Promise.all([loadSuiteInterfaces(), loadSuiteCases()])
}

const loadSuiteInterfaces = async () => {
  if (!currentSuite.value) return
  detailLoading.value = true
  try {
    const token = localStorage.getItem('token')
    const res = await axios.get(`/api/test-suites/${currentSuite.value.id}`,{headers:{Authorization:`Bearer ${token}`}})
    suiteInterfaces.value = res.data.items || []
  } catch (e: any) {
    ElMessage.error(`加载失败: ${e.message}`)
    suiteInterfaces.value = []
  } finally {
    detailLoading.value = false
  }
}

const loadSuiteCases = async () => {
  if (!currentSuite.value) return
  casesLoading.value = true
  try {
    const token = localStorage.getItem('token')
    // 获取该测试集关联的用例（通过 case_id 关联）
    const res = await axios.get(`/api/cases/?project_id=${props.projectId}`, {
      headers: { Authorization: `Bearer ${token}` }
    })
    const allCases = res.data?.items || res.data || []
    // 这里需要后端支持用例关联测试集，暂时显示空
    suiteCases.value = []
  } catch (e: any) {
    suiteCases.value = []
  } finally {
    casesLoading.value = false
  }
}

const removeItem = async (itemId: number, index: number) => {
  if (!currentSuite.value) return
  try {
    const token = localStorage.getItem('token')
    await axios.delete(`/api/test-suites/${currentSuite.value.id}/items/${itemId}`,{headers:{Authorization:`Bearer ${token}`}})
    ElMessage.success('已移除')
    suiteInterfaces.value.splice(index, 1)
    await loadSuites()
  } catch (e: any) {
    ElMessage.error(`移除失败: ${e.message}`)
  }
}

const removeCase = async (caseId: number, index: number) => {
  suiteCases.value.splice(index, 1)
  ElMessage.success('已移除')
}

// 添加接口
const handleManageItems = async (row: Suite) => {
  currentSuite.value = row
  detailDialogVisible.value = true
  detailTab.value = 'interfaces'
  await loadSuiteInterfaces()
}

const showAddInterfaceDialog = async () => {
  addInterfaceDialogVisible.value = true
  interfacesLoading.value = true
  selectedInterfaces.value = []
  try {
    const token = localStorage.getItem('token')
    const res = await axios.get(`/api/interfaces/?project_id=${props.projectId}`,{headers:{Authorization:`Bearer ${token}`}})
    availableInterfaces.value = res.data.items || res.data || []
  } catch (e: any) {
    ElMessage.error(`加载失败: ${e.message}`)
    availableInterfaces.value = []
  } finally {
    interfacesLoading.value = false
  }
}

const handleSelectionChange = (selection: any[]) => {
  selectedInterfaces.value = selection
}

const handleAddInterfaces = async () => {
  if (!currentSuite.value || !selectedInterfaces.value.length) return
  try {
    const token = localStorage.getItem('token')
    for (const item of selectedInterfaces.value) {
      await axios.post(`/api/test-suites/${currentSuite.value.id}/items`, {
        interface_id: item.id,
        name: item.name,
        method: item.method,
        url: item.url,
        headers: item.headers,
        params: item.params,
        body: item.body,
        body_type: item.body_type || 'json',
        order_index: suiteInterfaces.value.length,
        enabled: true
      }, { headers: { Authorization: `Bearer ${token}` } })
    }
    ElMessage.success(`已添加 ${selectedInterfaces.value.length} 个接口`)
    addInterfaceDialogVisible.value = false
    await loadSuiteInterfaces()
    await loadSuites()
  } catch (e: any) {
    ElMessage.error(`添加失败: ${e.message}`)
  }
}

// 添加用例
const showAddCaseDialog = async () => {
  addCaseDialogVisible.value = true
  casesLoading.value = true
  selectedCases.value = []
  try {
    const token = localStorage.getItem('token')
    const res = await axios.get(`/api/cases/?project_id=${props.projectId}`,{headers:{Authorization:`Bearer ${token}`}})
    availableCases.value = res.data.items || res.data || []
  } catch (e: any) {
    ElMessage.error(`加载失败: ${e.message}`)
    availableCases.value = []
  } finally {
    casesLoading.value = false
  }
}

const handleCaseSelectionChange = (selection: any[]) => {
  selectedCases.value = selection
}

const handleAddCases = async () => {
  // TODO: 后端需要支持用例关联测试集
  ElMessage.info('用例关联功能开发中')
  addCaseDialogVisible.value = false
}

// 变量提取配置
const varExtractDialogVisible = ref(false)
const currentVarExtracts = ref<Record<string, string>>({})
const editingItemId = ref<number | null>(null)

const openVarExtractConfig = (row: any) => {
  editingItemId.value = row.id
  currentVarExtracts.value = row.var_extracts || {}
  varExtractDialogVisible.value = true
}

const saveVarExtracts = async () => {
  if (!editingItemId.value) return
  try {
    const token = localStorage.getItem('token')
    // 过滤空值
    const varExtracts = Object.fromEntries(
      Object.entries(currentVarExtracts.value).filter(([k, v]) => k && v)
    )
    await axios.put(`/api/test-suites/${currentSuite.value?.id}/items/${editingItemId.value}`, {
      var_extracts: varExtracts
    }, { headers: { Authorization: `Bearer ${token}` } })
    ElMessage.success('变量提取配置已保存')
    varExtractDialogVisible.value = false
    await loadSuiteInterfaces()
  } catch (e: any) {
    ElMessage.error(`保存失败: ${e.message}`)
  }
}

// 参数化配置
const paramData = ref<any[]>([])
const paramColumns = ref<string[]>([])
const executingParams = ref(false)

// 测试结果
const testResults = ref<any[]>([])
const resultsLoading = ref(false)

// 导入数据
const importDataDialogVisible = ref(false)
const previewData = ref<any[]>([])
const importFile = ref<any>(null)

const showImportDataDialog = () => {
  importDataDialogVisible.value = true
  previewData.value = []
  importFile.value = null
}

const handleFileChange = (file: any) => {
  importFile.value = file
  // 简单解析 - 实际项目中需要用 xlsx 库解析
  ElMessage.info('文件已选择，请确认导入')
  // 模拟预览数据
  paramColumns.value = ['username', 'password']
  previewData.value = [
    { username: 'test1', password: '123456' },
    { username: 'test2', password: 'abcdef' }
  ]
}

const confirmImportData = () => {
  paramData.value = [...previewData.value]
  importDataDialogVisible.value = false
  ElMessage.success(`已导入 ${paramData.value.length} 组数据`)
}

const showAddParamRow = () => {
  const newRow: Record<string, string> = {}
  paramColumns.value.forEach(col => newRow[col] = '')
  paramData.value.push(newRow)
}

const executeWithParams = async () => {
  if (!currentSuite.value || !paramData.value.length) return
  executingParams.value = true
  try {
    const token = localStorage.getItem('token')
    // 逐组执行
    for (let i = 0; i < paramData.value.length; i++) {
      const params = paramData.value[i]
      await axios.post(`/api/test-suites/${currentSuite.value.id}/execute`, params, {
        headers: { Authorization: `Bearer ${token}` }
      })
    }
    ElMessage.success(`已执行 ${paramData.value.length} 组数据`)
    await loadTestResults()
  } catch (e: any) {
    ElMessage.error(`执行失败: ${e.message}`)
  } finally {
    executingParams.value = false
  }
}

const loadTestResults = async () => {
  if (!currentSuite.value) return
  resultsLoading.value = true
  try {
    const token = localStorage.getItem('token')
    const res = await axios.get(`/api/test-results/?suite_id=${currentSuite.value.id}`, {
      headers: { Authorization: `Bearer ${token}` }
    })
    testResults.value = res.data || []
  } catch (e: any) {
    testResults.value = []
  } finally {
    resultsLoading.value = false
  }
}

// 查看结果详情
const viewResultDetail = async (row: any) => {
  try {
    const token = localStorage.getItem('token')
    const res = await axios.get(`/api/test-results/${row.id}`, {
      headers: { Authorization: `Bearer ${token}` }
    })
    // 显示详细结果对话框
    resultDetailVisible.value = true
    currentResultDetail.value = res.data
  } catch (e: any) {
    ElMessage.error(`加载详情失败：${e.message}`)
  }
}

// 删除结果
const deleteResult = async (id: number) => {
  try {
    const token = localStorage.getItem('token')
    await axios.delete(`/api/test-results/${id}`, {
      headers: { Authorization: `Bearer ${token}` }
    })
    ElMessage.success('已删除')
    await loadTestResults()
  } catch (e: any) {
    ElMessage.error(`删除失败：${e.message}`)
  }
}

// 结果详情
const resultDetailVisible = ref(false)
const currentResultDetail = ref<any>(null)

onMounted(() => {loadSuites();loadModules()})
</script>

<style scoped>
.text-muted { color: #999; }
.result-item.success { background: #f6ffed; border: 1px solid #b7eb8f; }
.result-item.fail { background: #fff2f0; border: 1px solid #ffccc7; }
</style>
