<template>
  <div class="test-execution">
    <el-row :gutter="16" style="margin-bottom: 16px">
      <el-col :span="6"><el-card><div class="stat"><div class="stat-value">{{stats.total}}</div><div class="stat-label">总执行次数</div></div></el-card></el-col>
      <el-col :span="6"><el-card><div class="stat"><div class="stat-value" style="color:#67C23A">{{stats.passed}}</div><div class="stat-label">通过</div></div></el-card></el-col>
      <el-col :span="6"><el-card><div class="stat"><div class="stat-value" style="color:#F56C6C">{{stats.failed}}</div><div class="stat-label">失败</div></div></el-card></el-col>
      <el-col :span="6"><el-card><div class="stat"><div class="stat-value" style="color:#409EFF">{{stats.passRate}}%</div><div class="stat-label">通过率</div></div></el-card></el-col>
    </el-row>
    
    <div style="margin-bottom:16px">
      <el-select v-model="filter" style="width:120px;margin-right:8px">
        <el-option label="全部" value="all" /><el-option label="通过" value="passed" /><el-option label="失败" value="failed" />
      </el-select>
      <el-button @click="loadExecutions"><el-icon><Refresh /></el-icon>刷新</el-button>
      <el-button @click="handleExport" :disabled="!executions.length"><el-icon><Download /></el-icon>导出</el-button>
    </div>

    <el-table :data="filteredExecutions" row-key="id" v-loading="loading" empty-text="暂无执行记录">
      <el-table-column label="测试集" width="120">
        <template #default="{row}">
          <span>测试集 #{{ row.suite_id }}</span>
        </template>
      </el-table-column>
      <el-table-column prop="status" label="状态">
        <template #default="{row}">
          <el-tag :type="row.status==='passed'?'success':row.status==='failed'?'danger':'info'">{{row.status==='passed'?'通过':row.status==='failed'?'失败':'运行中'}}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="total" label="总数" />
      <el-table-column prop="passed" label="通过"><template #default="{row}"><el-tag type="success">{{row.passed}}</el-tag></template></el-table-column>
      <el-table-column prop="failed" label="失败"><template #default="{row}"><el-tag type="danger">{{row.failed}}</el-tag></template></el-table-column>
      <el-table-column prop="duration_ms" label="耗时"><template #default="{row}">{{row.duration_ms?row.duration_ms+'ms':'-'}}</template></el-table-column>
      <el-table-column prop="executed_at" label="执行时间" />
      <el-table-column label="操作" width="80">
        <template #default="{row}">
          <el-button type="primary" link size="small" @click="viewResultDetail(row)">详情</el-button>
        </template>
      </el-table-column>
    </el-table>

    <!-- 结果详情对话框 -->
    <el-dialog v-model="detailDialogVisible" title="执行详情" width="800px">
      <div v-if="currentDetail">
        <el-alert :type="currentDetail.status==='passed'?'success':'error'" style="margin-bottom:16px">
          执行结果: {{ currentDetail.status === 'passed' ? '通过' : '失败' }} | 
          通过: {{ currentDetail.passed }}/{{ currentDetail.total }} | 
          耗时: {{ currentDetail.duration_ms }}ms
        </el-alert>
        <el-table :data="detailItems" size="small">
          <el-table-column prop="interface_name" label="接口" />
          <el-table-column prop="method" label="方法" width="70" />
          <el-table-column prop="status_code" label="状态码" width="80">
            <template #default="{row}">
              <el-tag :type="row.status_code>=200 && row.status_code<300?'success':'danger'" size="small">
                {{ row.status_code || '-' }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="elapsed_ms" label="耗时" width="80" />
          <el-table-column label="操作" width="80">
            <template #default="{row}">
              <el-button type="primary" link size="small" @click="viewItemResponse(row)">响应</el-button>
            </template>
          </el-table-column>
        </el-table>
      </div>
    </el-dialog>

    <!-- 响应详情对话框 -->
    <el-dialog v-model="responseDialogVisible" title="响应详情" width="700px">
      <div v-if="currentResponse">
        <el-descriptions :column="2" border>
          <el-descriptions-item label="状态码">
            <el-tag :type="currentResponse.status_code>=200 && currentResponse.status_code<300?'success':'danger'">
              {{ currentResponse.status_code || '-' }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="耗时">{{ currentResponse.elapsed_ms }}ms</el-descriptions-item>
        </el-descriptions>
        <div style="margin-top:12px">
          <div style="font-weight:bold;margin-bottom:8px">响应体:</div>
          <pre style="background:#f5f5f5;padding:12px;max-height:400px;overflow:auto;font-size:12px">{{ formatResponse(currentResponse.response?.body) }}</pre>
        </div>
        <div v-if="currentResponse.extracted_vars && Object.keys(currentResponse.extracted_vars).length" style="margin-top:12px">
          <div style="font-weight:bold;margin-bottom:8px">提取的变量:</div>
          <el-tag v-for="(v,k) in currentResponse.extracted_vars" :key="k" style="margin-right:8px;margin-bottom:8px">
            {{ k }}: {{ v }}
          </el-tag>
        </div>
      </div>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { Refresh, Download } from '@element-plus/icons-vue'
import axios from 'axios'

const props = defineProps<{projectId:number}>()

interface Execution { id:number; suite_id:number; suite_name:string; status:'passed'|'failed'|'running'; total:number; passed:number; failed:number; duration_ms?:number; executed_at:string }

const loading = ref(false)
const executions = ref<Execution[]>([])
const filter = ref<'all'|'passed'|'failed'>('all')

// 详情对话框
const detailDialogVisible = ref(false)
const responseDialogVisible = ref(false)
const currentDetail = ref<any>(null)
const currentResponse = ref<any>(null)
const detailItems = ref<any[]>([])
const detailTab = ref('items')

const filteredExecutions = computed(() => {
  if(filter.value==='all') return executions.value
  return executions.value.filter(e => e.status === filter.value)
})

const stats = computed(() => ({
  total: executions.value.length,
  passed: executions.value.filter(e => e.status==='passed').length,
  failed: executions.value.filter(e => e.status==='failed').length,
  passRate: executions.value.length ? (executions.value.filter(e=>e.status==='passed').length/executions.value.length*100).toFixed(1) : '0'
}))

const loadExecutions = async () => {
  loading.value = true
  try{
    const token=localStorage.getItem('token')
    const res=await axios.get(`/api/test-results/?limit=100`,{headers:{Authorization:`Bearer ${token}`}})
    const data = Array.isArray(res.data) ? res.data : []
    // 转换后端字段为前端字段
    executions.value = data.map((r:any) => ({
      id: r.id,
      suite_id: r.suite_id,
      status: r.status === 'success' ? 'passed' : r.status === 'failed' ? 'failed' : 'running',
      total: r.total_count || 0,
      passed: r.success_count || 0,
      failed: r.fail_count || 0,
      duration_ms: r.duration_ms,
      executed_at: r.finished_at || r.started_at || ''
    }))
  }catch(e:any){
    console.error('加载失败:', e)
    executions.value=[]
  }
  finally{loading.value=false}
}

const handleExport = () => {
  const d = executions.value.map(e=>({suite_name:e.suite_name,status:e.status,total:e.total,passed:e.passed,failed:e.failed,duration_ms:e.duration_ms,executed_at:e.executed_at}))
  const b = new Blob([JSON.stringify(d,null,2)],{type:'application/json'})
  const u = URL.createObjectURL(b);const a=document.createElement('a');a.href=u;a.download=`executions_${new Date().toISOString().slice(0,10)}.json`;a.click();URL.revokeObjectURL(u);ElMessage.success('导出成功')
}

// 查看执行详情
const viewResultDetail = async (row: Execution) => {
  try {
    const token = localStorage.getItem('token')
    const res = await axios.get(`/api/test-results/${row.id}`, { headers: { Authorization: `Bearer ${token}` } })
    currentDetail.value = res.data
    const details = res.data.details
    if (details && details.items) {
      detailItems.value = details.items
    } else {
      detailItems.value = []
    }
    detailDialogVisible.value = true
  } catch (e: any) {
    ElMessage.error('加载详情失败: ' + e.message)
  }
}

// 查看响应详情
const viewItemResponse = (item: any) => {
  currentResponse.value = item
  responseDialogVisible.value = true
}

// 格式化响应
const formatResponse = (body: any) => {
  if (!body) return '无响应内容'
  if (typeof body === 'string') return body
  return JSON.stringify(body, null, 2)
}

onMounted(() => {loadExecutions()})
</script>

<style scoped>
.stat{text-align:center}
.stat-value{font-size:24px;font-weight:bold}
.stat-label{color:#888;font-size:14px;margin-top:4px}
</style>
