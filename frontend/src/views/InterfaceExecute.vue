<template>
  <div class="interface-execute">
    <div class="header">
      <h1>🔌 接口自动化测试</h1>
      <div class="header-actions">
        <el-button type="primary" @click="importDialogVisible = true">
          <el-icon><Upload /></el-icon>导入
        </el-button>
        <el-dropdown @command="handleDownloadTemplate">
          <el-button><el-icon><Download /></el-icon>模板</el-button>
          <template #dropdown>
            <el-dropdown-menu>
              <el-dropdown-item command="excel">Excel (.xlsx)</el-dropdown-item>
              <el-dropdown-item command="json">JSON</el-dropdown-item>
              <el-dropdown-item command="yaml">YAML</el-dropdown-item>
            </el-dropdown-menu>
          </template>
        </el-dropdown>
        <el-button @click="handleExport" :disabled="!interfaces.length"><el-icon><Download /></el-icon>导出({{selectedRows.length || '全部'}})</el-button>
        <el-button type="success" @click="handleGenerateReport" :disabled="!interfaces.length"><el-icon><Document /></el-icon>报告</el-button>
      </div>
    </div>

    <el-tabs v-model="activeTab">
      <el-tab-pane label="手动测试" name="manual">
        <el-row :gutter="16">
          <el-col :span="16">
            <el-card class="request-card">
              <template #header>
                <div class="card-header">
                  <span>📡 接口配置</span>
                  <div>
                    <el-button type="primary" @click="handleExecute" :loading="executing">
                      <el-icon><CaretRight /></el-icon>发送
                    </el-button>
                    <el-button @click="handleSaveInterface"><el-icon><FolderAdd /></el-icon>保存</el-button>
                    <el-button @click="chainDialogVisible = true; loadSavedChains()">
                      <el-icon><Link /></el-icon>执行链
                    </el-button>
                  </div>
                </div>
              </template>
              
              <div class="request-line">
                <el-button type="success" @click="handleCreateNew" title="新建接口">+ 新建</el-button>
                <el-select v-model="requestConfig.method" style="width: 100px">
                  <el-option label="GET" value="GET" /><el-option label="POST" value="POST" />
                  <el-option label="PUT" value="PUT" /><el-option label="DELETE" value="DELETE" />
                  <el-option label="PATCH" value="PATCH" />
                </el-select>
                <el-input v-model="requestConfig.url" placeholder="请求URL" style="flex: 1" />
                <el-select v-model="requestConfig.bodyType" style="width: 130px">
                  <el-option label="JSON" value="json" /><el-option label="FormData" value="form-data" />
                  <el-option label="URLEncoded" value="x-www-form-urlencoded" /><el-option label="Raw" value="raw" />
                </el-select>
              </div>
              <el-input v-model="requestConfig.name" placeholder="接口名称" style="margin-bottom: 12px" />
              <el-input v-model="requestConfig.description" placeholder="接口描述" style="margin-bottom: 12px" />

              <el-tabs v-model="requestTab">
                <el-tab-pane label="Params" name="params">
                  <el-input v-model="requestConfig.params" type="textarea" :rows="2" placeholder='{"key": "value"}' />
                </el-tab-pane>
                <el-tab-pane label="Headers" name="headers">
                  <el-input v-model="requestConfig.headers" type="textarea" :rows="2" placeholder='{"Content-Type": "application/json"}' />
                </el-tab-pane>
                <el-tab-pane label="Body" name="body">
                  <div v-if="requestConfig.bodyType === 'json' || requestConfig.bodyType === 'raw'">
                    <el-input v-model="requestConfig.body" type="textarea" :rows="6" placeholder='{"key": "value"}' />
                  </div>
                  <div v-else-if="requestConfig.bodyType === 'form-data' || requestConfig.bodyType === 'x-www-form-urlencoded'">
                    <div v-for="(p, i) in formDataParams" :key="i" class="param-row">
                      <el-checkbox v-model="p.enabled" />
                      <el-input v-model="p.key" placeholder="Key" style="width: 200px" />
                      <el-input v-model="p.value" placeholder="Value" style="flex: 1" />
                      <el-button type="danger" circle @click="formDataParams.splice(i, 1)">×</el-button>
                    </div>
                    <el-button type="default" @click="formDataParams.push({key:'',value:'',enabled:true})" style="width:100%;margin-top:8px">+ 添加参数</el-button>
                  </div>
                  <div class="assertion-box">
                    <div class="assertion-title">⚠️ 断言配置</div>
                    <div v-for="(a, i) in assertions" :key="i" class="param-row">
                      <el-checkbox v-model="a.enabled" />
                      <el-select v-model="a.type" style="width:150px">
                        <el-option label="状态码" value="statusCode" /><el-option label="响应体包含" value="bodyContains" />
                        <el-option label="响应体等于" value="bodyEquals" /><el-option label="响应时间<ms>" value="responseTime" />
                      </el-select>
                      <el-input v-model="a.expected" placeholder="期望值" style="flex:1" />
                      <el-button type="danger" circle @click="assertions.splice(i,1)">×</el-button>
                    </div>
                    <el-button type="default" @click="assertions.push({type:'statusCode',expected:200,enabled:true})" style="width:100%;margin-top:8px">+ 添加断言</el-button>
                  </div>
                </el-tab-pane>
              </el-tabs>
            </el-card>

            <el-card class="response-card" style="margin-top: 16px">
              <template #header>
                <div class="card-header">
                  <span>📝 请求结果</span>
                </div>
              </template>
              <div v-if="responseResult?.results">
                <el-card v-for="(r,idx) in responseResult?.results" :key="idx" :class="['chain-item', r.result?.status_code>=400?'fail':'success']">
                  <template #header>
                    <div style="display:flex;align-items:center;gap:8px">
                      <el-badge :value="idx+1" :type="r.result?.status_code>=400?'danger':'success'" />
                      <el-tag :type="r.result?.status_code>=400?'danger':'success'">{{ r.result?.status_code }}</el-tag>
                      <span>{{ r.name || `接口${idx+1}` }}</span>
                      <el-tag v-if="r.result?.elapsed_ms" type="info">{{ r.result?.elapsed_ms }}ms</el-tag>
                      <el-button type="link" size="small" @click="toggleExpand(idx)">{{ expandedResults.includes(idx)?'收起▲':'详情▼' }}</el-button>
                    </div>
                  </template>
                  <pre v-if="expandedResults.includes(idx)" class="response-pre">{{ JSON.stringify(r.result?.body||r.result,null,2) }}</pre>
                </el-card>
                <div class="chain-summary">
                  <el-tag type="info">总耗时: {{ responseResult?.elapsed_ms }}ms</el-tag>
                  <el-tag type="success">成功: {{ responseResult?.summary?.success }}</el-tag>
                  <el-tag type="danger">失败: {{ responseResult?.summary?.failed }}</el-tag>
                </div>
              </div>
              <div v-else-if="responseResult">
                <div class="result-meta" style="display: flex; gap: 8px; margin-bottom: 12px; flex-wrap: wrap;">
                  <el-tag v-if="responseResult?.result?.status_code" :type="responseResult?.result.status_code<400?'success':'danger'" style="font-size: 14px">
                    状态: {{ responseResult?.result.status_code }}
                  </el-tag>
                  <el-tag v-if="responseResult?.result?.elapsed_ms" type="info" style="font-size: 14px">
                    耗时: {{ responseResult?.result.elapsed_ms }}ms
                  </el-tag>
                  <el-tag v-if="responseResult?.passed!==undefined" :type="responseResult?.passed?'success':'danger'" style="font-size: 14px">
                    {{ responseResult?.passed?'✓ 通过':'✗ 失败' }}
                  </el-tag>
                  <el-tag v-if="responseResult?.result?.error" type="danger" style="font-size: 14px">
                    {{ responseResult?.result?.error }}
                  </el-tag>
                </div>
                <pre class="response-pre" @click="showJsonPathExtract(responseResult?.result?.body)" style="cursor:pointer" title="点击提取JSON路径">
{{ JSON.stringify(responseResult?.result?.body||responseResult,null,2) }}
</pre>
                <div v-if="jsonPathHint" style="margin-top:8px;padding:8px;background:#f0f9ff;border-radius:4px;font-size:12px">
                  <div style="display:flex;justify-content:space-between;align-items:center">
                    <span>💡 点击上方响应体可快速提取JSON Path</span>
                    <el-button link size="small" @click="jsonPathHint=false">知道了</el-button>
                  </div>
                </div>
              </div>
              <div v-else class="empty-response">点击「发送」查看结果</div>
            </el-card>
          </el-col>

          <el-col :span="8">
            <el-card class="interface-list-card">
              <template #header>
                <div class="card-header">
                  <span>📁 接口列表</span>
                  <el-button-group>
                    <el-button size="small" type="danger" :disabled="!selectedRows.length" @click="handleBatchDelete">删({{selectedRows.length}})</el-button>
                    <el-button size="small" type="primary" :disabled="!selectedRows.length" @click="handleBatchAddToChain">加链({{selectedRows.length}})</el-button>
                    <el-button size="small" :disabled="!selectedRows.length" @click="handleBatchSetPriority">优先级</el-button>
                    <el-button size="small" :disabled="!selectedRows.length" @click="handleBatchExecute">执行({{selectedRows.length}})</el-button>
                  </el-button-group>
                </div>
              </template>
              <div class="list-toolbar">
                <el-input v-model="searchText" placeholder="搜索..." clearable @input="handleSearch" style="flex:1" />
                <el-button :type="showFavoritesOnly?'warning':'default'" :icon="Star" @click="showFavoritesOnly=!showFavoritesOnly" />
              </div>
              <el-table :data="interfaces" size="small" highlight-current-row @row-click="handleSelectInterface" @selection-change="r=>selectedRows=r" :height="tableHeight">
                <el-table-column type="selection" width="40" />
                <el-table-column prop="name" label="名称" width="120" show-overflow-tooltip />
                <el-table-column prop="method" label="方法" width="55">
                  <template #default="{row}"><el-tag :type="getMethodType(row.method)" size="small">{{row.method}}</el-tag></template>
                </el-table-column>
                <el-table-column prop="url" label="URL" show-overflow-tooltip />
                <el-table-column label="操作" width="180">
                  <template #default="{row}">
                    <el-button type="primary" link size="small" @click.stop="handleEditInterface(row)">编辑</el-button>
                    <el-button type="primary" link size="small" @click.stop="handleCopyInterface(row)">复制</el-button>
                    <el-button type="primary" link size="small" @click.stop="handleExecuteInterface(row)">执行</el-button>
                    <el-button type="primary" link size="small" @click.stop="addToChain(row)">+链</el-button>
                  </template>
                </el-table-column>
              </el-table>
              <el-pagination v-model:current-page="pagination.current" v-model:page-size="pagination.pageSize" :total="pagination.total" :page-sizes="[10,20,50,100]" layout="total,sizes,prev,pager,next,jumper" @size-change="(val:number)=>{pagination.pageSize=val;loadInterfaces(1,val)}" @current-change="(val:number)=>loadInterfaces(val,pagination.pageSize)" style="margin-top:12px" />
            </el-card>

            <el-card style="margin-top: 16px">
              <template #header><span>🔗 接口链</span></template>
              <div v-if="!chainInterfaces.length" class="empty-chain">点击「+链」按钮添加</div>
              <div v-else>
                <div v-for="(i,idx) in chainInterfaces" :key="idx" class="chain-item-row">
                  <el-badge :value="idx+1" />
                  <el-tag :type="getMethodType(i.method)">{{i.method}}</el-tag>
                  <span style="flex:1;font-size:13px">{{i.name}}</span>
                  <el-input v-model="i.var_name" placeholder="变量" size="small" style="width:80px;margin-right:4px" />
                  <el-button size="small" @click="chainInterfaces.splice(idx,1)">×</el-button>
                </div>
                <el-button type="primary" style="width:100%;margin-top:12px" @click="handleExecuteChain" :loading="executing">执行接口链({{chainInterfaces.length}})</el-button>
              </div>
            </el-card>
          </el-col>
        </el-row>
      </el-tab-pane>

      <el-tab-pane label="测试集" name="suites"><test-suites :project-id="1" /></el-tab-pane>
      <el-tab-pane label="测试报告" name="reports"><test-execution :project-id="1" /></el-tab-pane>
      <el-tab-pane label="环境管理" name="environments"><environment-management :project-id="1" /></el-tab-pane>
    </el-tabs>

    <el-dialog v-model="importDialogVisible" title="导入接口" width="500px">
      <p>支持: Excel(.xlsx), CSV, YAML, JSON</p>
      <el-upload drag action="/api/interfaces/import?project_id=1" :headers="uploadHeaders" :on-success="handleImportSuccess" :on-error="handleImportError" :on-change="(file) => console.log('File:', file)" accept=".xlsx,.xls,.csv,.yaml,.yml,.json" :auto-upload="true" :with-credentials="true">
        <el-icon class="el-icon--upload"><Upload /></el-icon>
        <div class="el-upload__text">点击或拖拽上传</div>
      </el-upload>
    </el-dialog>

    <!-- JSON Path 选择对话框 -->
    <el-dialog v-model="jsonPathDialogVisible" title="提取 JSON Path" width="500px">
      <el-alert type="info" :closable="false" style="margin-bottom:12px">
        点击路径即可复制，然后可以在变量提取中使用，如: {"token": "$.data.token"}
      </el-alert>
      <div style="max-height: 400px; overflow-y: auto;">
        <div v-for="path in jsonPathOptions" :key="path" @click="copyJsonPath(path)" style="padding:8px 12px;cursor:pointer;border-bottom:1px solid #eee;font-family:monospace;font-size:13px">
          {{ path }}
        </div>
      </div>
    </el-dialog>

    <el-dialog v-model="chainDialogVisible" title="接口链配置" width="600px">
      <div v-if="savedChains.length" style="margin-bottom:16px">
        <div style="margin-bottom:8px;font-weight:500">已保存的测试集：</div>
        <el-tag v-for="c in savedChains" :key="c.id" type="primary" style="cursor:pointer;margin-right:8px;margin-bottom:8px" @click="loadSavedChain(c.id)">
          {{c.name}} 
          <span v-if="c.collection_id" style="font-size:10px;opacity:0.8">(集合{{c.collection_id}})</span>
        </el-tag>
      </div>
      <div v-if="!chainInterfaces.length" class="empty-chain">从接口列表添加或选择已保存的接口链</div>
      <div v-else>
        <div style="margin-bottom:12px;display:flex">
          <el-input v-model="chainName" placeholder="输入名称保存" style="flex:1" />
          <el-button type="primary" @click="handleSaveChain" style="margin-left:8px">保存</el-button>
        </div>
        <el-tag type="info">共 {{chainInterfaces.length}} 个接口</el-tag>
        <div v-for="(i,idx) in chainInterfaces" :key="idx" class="chain-item-row">
          <el-badge :value="idx+1" /><el-tag type="primary">{{i.method}}</el-tag><span>{{i.name}}</span>
        </div>
        <el-button type="primary" style="width:100%;margin-top:16px" @click="handleExecuteChain" :loading="executing">执行({{chainInterfaces.length}})</el-button>
      </div>
    </el-dialog>

    <el-dialog v-model="saveDialogVisible" title="保存接口" width="500px">
      <el-form :model="saveForm" label-width="80px">
        <el-form-item label="名称"><el-input v-model="saveForm.name" /></el-form-item>
        <el-form-item label="描述"><el-input v-model="saveForm.description" /></el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="saveDialogVisible=false">取消</el-button>
        <el-button type="primary" @click="confirmSaveInterface">保存</el-button>
      </template>
    </el-dialog>

    <!-- 批量设置优先级对话框 -->
    <el-dialog v-model="priorityDialogVisible" title="批量设置优先级" width="400px">
      <el-alert type="info" :closable="false" style="margin-bottom:16px">
        将为 {{selectedRows.length}} 个选中接口设置优先级
      </el-alert>
      <el-select v-model="setPriorityValue" placeholder="选择优先级" style="width:100%">
        <el-option label="P0 - 核心" value="P0" />
        <el-option label="P1 - 重要" value="P1" />
        <el-option label="P2 - 一般" value="P2" />
        <el-option label="P3 - 低" value="P3" />
        <el-option label="清除优先级" value="" />
      </el-select>
      <template #footer>
        <el-button @click="priorityDialogVisible=false">取消</el-button>
        <el-button type="primary" @click="confirmSetPriority">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted, defineAsyncComponent } from 'vue'
import { ElMessage } from 'element-plus'
import { Upload, Download, CaretRight, Link, Star, FolderAdd, Document } from '@element-plus/icons-vue'
import axios from 'axios'

const TestSuites = defineAsyncComponent(() => import('./TestSuites.vue'))
const TestExecution = defineAsyncComponent(() => import('./TestExecution.vue'))
const EnvironmentManagement = defineAsyncComponent(() => import('./EnvironmentManagement.vue'))

interface IF { id?:number; name:string; method:string; url:string; description?:string; headers?:any; params?:any; body?:any; body_type?:string; is_favorite?:boolean; last_status_code?:number; last_response_time?:number; var_name?:string }
interface Res { result?:{status_code:number;headers:any;body:any;elapsed_ms:number}; summary?:{total:number;success:number;failed:number}; results?:any[]; passed?:boolean; elapsed_ms?:number }

const uploadHeaders = computed(() => ({ Authorization: `Bearer ${localStorage.getItem('token')}` }))

const activeTab = ref('manual')
const interfaces = ref<IF[]>([])
const selectedRows = ref<IF[]>([])
const searchText = ref('')
const showFavoritesOnly = ref(false)
const tableHeight = ref(500)
const executing = ref(false)
const chainDialogVisible = ref(false)
const importDialogVisible = ref(false)
const saveDialogVisible = ref(false)
const pagination = ref({current:1, pageSize:20, total:0})

const requestConfig = reactive({ id:null as number|null, method:'GET', url:'', name:'', description:'', headers:'', params:'', body:'', bodyType:'json' })
const requestTab = ref('params')
const responseResult = ref<Res|null>(null)
const chainInterfaces = ref<IF[]>([])
const savedChains = ref<{id:number,name:string}[]>([])
const chainName = ref('')
const formDataParams = ref([{key:'',value:'',enabled:true}])
const assertions = ref([{type:'statusCode',expected:200,enabled:true}])
const expandedResults = ref<number[]>([])
const jsonPathHint = ref(true)

// 提取JSON Path的工具函数
const extractJsonPaths = (obj: any, prefix = '$'): string[] => {
  const paths: string[] = []
  if (obj && typeof obj === 'object') {
    for (const key of Object.keys(obj)) {
      const currentPath = `${prefix}.${key}`
      paths.push(currentPath)
      if (Array.isArray(obj[key])) {
        paths.push(`${currentPath}[0]`)  // 数组第一个元素
      } else if (typeof obj[key] === 'object' && obj[key] !== null) {
        paths.push(...extractJsonPaths(obj[key], currentPath))
      }
    }
  }
  return paths
}

const showJsonPathExtract = (body: any) => {
  if (!body) return
  const paths = extractJsonPaths(body)
  if (paths.length > 0) {
    // 显示所有路径供选择
    jsonPathOptions.value = paths.slice(0, 50) // 限制50个
    jsonPathDialogVisible.value = true
  } else {
    ElMessage.warning('无法提取路径')
  }
}

// JSON Path 选择对话框
const jsonPathDialogVisible = ref(false)
const jsonPathOptions = ref<string[]>([])
const selectedJsonPath = ref('')
const copyJsonPath = (path: string) => {
  navigator.clipboard.writeText(path)
  selectedJsonPath.value = path
  ElMessage.success(`已复制: ${path}`)
}

const saveForm = reactive({name:'', description:''})

const getMethodType = (m:string) => ({GET:'success',POST:'primary',PUT:'warning',DELETE:'danger',PATCH:'info'}[m]||'info')

const loadInterfaces = async (page=1, pageSize=20) => {
  try {
    const offset = (page-1)*pageSize
    const token = localStorage.getItem('token')
    const res = await axios.get(`/api/interfaces/?limit=${pageSize}&offset=${offset}&search=${searchText.value}&favorites_only=${showFavoritesOnly.value}&project_id=1`, {headers:{Authorization:`Bearer ${token}`}})
    const d = res.data
    // 兼容多种返回格式
    if(Array.isArray(d)){
      interfaces.value=d
      pagination.value.total=d.length
    }else if(d && typeof d === 'object'){
      interfaces.value=d.items || d.data || []
      pagination.value.total=d.total || d.count || interfaces.value.length
    }else{
      interfaces.value=[]
      pagination.value.total=0
    }
  }catch(e:any){
    console.error('加载接口失败:', e)
    interfaces.value=[]
  }
}
const handleSearch = () => {pagination.value.current=1;loadInterfaces()}

// 新建接口 - 清空表单
const handleCreateNew = () => {
  requestConfig.id = null
  requestConfig.method = 'GET'
  requestConfig.url = ''
  requestConfig.name = ''
  requestConfig.description = ''
  requestConfig.headers = ''
  requestConfig.params = ''
  requestConfig.body = ''
  requestConfig.bodyType = 'json'
  ElMessage.info('请填写接口信息，然后点击保存')
}

const handleSelectInterface = (row:IF) => {
  requestConfig.id=row.id||null;requestConfig.method=row.method||'GET';requestConfig.url=row.url||''
  requestConfig.headers=row.headers?(typeof row.headers==='string'?row.headers:JSON.stringify(row.headers,null,2)):''
  requestConfig.params=row.params?(typeof row.params==='string'?row.params:JSON.stringify(row.params,null,2)):''
  requestConfig.body=row.body?(typeof row.body==='string'?row.body:JSON.stringify(row.body,null,2)):''
  requestConfig.bodyType=row.body_type||'json';requestConfig.name=row.name||'';requestConfig.description=row.description||''
}

// 编辑接口 - 直接填充到左侧，不弹窗
const handleEditInterface = (row:IF) => {
  handleSelectInterface(row)
  ElMessage.success(`已加载接口「${row.name}」，修改后点击保存`)
}

// 复制接口
const handleCopyInterface = (row:IF) => {
  handleSelectInterface({...row,name:(row.name||'')+'_副本',id:undefined})
  ElMessage.success('已复制，请修改名称后保存')
}

const handleExecuteInterface = async (row:IF) => {
  executing.value=true
  try{
    const token = localStorage.getItem('token')
    const res = await axios.post(`/api/interfaces/execute-direct`,{method:row.method,url:row.url,headers:row.headers,params:row.params,body:row.body,body_type:row.body_type||'json',save_result:true},{headers:{Authorization:`Bearer ${token}`}})
    responseResult.value=res.data?.result;ElMessage.success(`执行${res.data.passed?'通过':'失败'}`);setTimeout(()=>loadInterfaces(),1500)
  }catch(e:any){ElMessage.error(`执行失败: ${e.message}`)}
  finally{executing.value=false}
}

const handleExecute = async () => {
  if(!requestConfig.url){ElMessage.warning('请输入URL');return}
  executing.value=true;responseResult.value=null
  try{
    const token = localStorage.getItem('token')
    let h={},p={},b={}
    try{h=requestConfig.headers?JSON.parse(requestConfig.headers):{}}catch{}
    try{p=requestConfig.params?JSON.parse(requestConfig.params):{}}catch{}
    try{b=requestConfig.body?JSON.parse(requestConfig.body):{}}catch{}
    if(requestConfig.bodyType==='form-data'||requestConfig.bodyType==='x-www-form-urlencoded'){formDataParams.value.forEach(x=>{if(x.enabled&&x.key)b[x.key]=x.value})}
    const start=Date.now()
    const res = await axios.post('/api/interfaces/execute-direct',{
      method: requestConfig.method,
      url: requestConfig.url,
      headers: h,
      params: p,
      body: b,
      body_type: requestConfig.bodyType,
      interface_id: requestConfig.id,
      save_result: !!requestConfig.id,
      assertions: assertions.value.filter(x=>x.enabled).map(x=>({type:x.type,expected:x.expected}))
    },{headers:{Authorization:`Bearer ${token}`}})
    responseResult.value=res.data
    ElMessage.success(`已发送！状态: ${res.data.result?.status_code}，耗时: ${res.data.result?.elapsed_ms}ms，${res.data.passed?'✓通过':'✗失败'}`)
  }catch(e:any){ElMessage.error(`请求失败: ${e.message}`)}
  finally{executing.value=false}
}

const handleSaveInterface = () => {
  if(!requestConfig.name||!requestConfig.url){ElMessage.warning('请填写名称和URL');return}
  saveForm.name=requestConfig.name;saveForm.description=requestConfig.description;saveDialogVisible.value=true
}
const confirmSaveInterface = async () => {
  try{
    const token = localStorage.getItem('token')
    let h={},p={},b={}
    try{h=requestConfig.headers?JSON.parse(requestConfig.headers):{}}catch{}
    try{p=requestConfig.params?JSON.parse(requestConfig.params):{}}catch{}
    try{b=requestConfig.body?JSON.parse(requestConfig.body):{}}catch{}
    // 构建接口数据
    const data = {
      name: saveForm.name || requestConfig.name,
      api_code: requestConfig.api_code || `api.${Date.now()}`,
      api_name: saveForm.name || requestConfig.name,
      method: requestConfig.method,
      path: requestConfig.url,
      url: requestConfig.url,
      description: saveForm.description || requestConfig.description,
      headers: h,
      params: p,
      body: b,
      body_type: requestConfig.bodyType || 'json',
      project_id: 1
    }
    if(requestConfig.id){await axios.put(`/api/interfaces/${requestConfig.id}`,data,{headers:{Authorization:`Bearer ${token}`}});ElMessage.success('已更新')}
    else{await axios.post('/api/interfaces/',data,{headers:{Authorization:`Bearer ${token}`}});ElMessage.success('已保存')}
    saveDialogVisible.value=false;loadInterfaces()
  }catch(e:any){ElMessage.error(`保存失败: ${e.response?.data?.detail || e.message}`)}
}

const handleBatchDelete = async () => {
  try{const token=localStorage.getItem('token')
    for(const r of selectedRows.value)if(r.id)await axios.delete(`/api/interfaces/${r.id}`,{headers:{Authorization:`Bearer ${token}`}})
    ElMessage.success(`已删除${selectedRows.value.length}个`);selectedRows.value=[];loadInterfaces()
  }catch(e:any){ElMessage.error(`删除失败: ${e.message}`)}
}
const handleBatchExecute = async () => {
  if(!selectedRows.value.length)return
  executing.value=true;const results:any[]=[]
  try{const token=localStorage.getItem('token')
    for(const r of selectedRows.value)try{const res=await axios.post(`/api/interfaces/execute-direct`,{method:r.method,url:r.url,headers:r.headers,params:r.params,body:r.body,body_type:r.body_type||'json',save_result:true},{headers:{Authorization:`Bearer ${token}`}});results.push({name:r.name,...res.data})}catch(e:any){results.push({name:r.name,error:e.message})}
    const ok=results.filter(x=>x.passed).length;ElMessage.success(`完成: ${ok}/${results.length}成功`)
    responseResult.value={results,summary:{total:results.length,success:ok,failed:results.length-ok}};selectedRows.value=[];loadInterfaces()
  }catch(e:any){ElMessage.error(`失败: ${e.message}`)}
  finally{executing.value=false}
}
const handleBatchAddToChain = () => {chainInterfaces.value.push(...selectedRows.value);ElMessage.success(`已添加${selectedRows.value.length}个`);selectedRows.value=[]}

// 批量设置优先级
const priorityDialogVisible = ref(false)
const setPriorityValue = ref('')
const handleBatchSetPriority = () => {
  if(!selectedRows.value.length){ElMessage.warning('请选择接口');return}
  priorityDialogVisible.value=true
}
const confirmSetPriority = async () => {
  if(!setPriorityValue.value){ElMessage.warning('请选择优先级');return}
  const token = localStorage.getItem('token')
  let success = 0
  for(const row of selectedRows.value){
    if(row.id)try{
      await axios.put(`/api/interfaces/${row.id}`,{priority:setPriorityValue.value},{headers:{Authorization:`Bearer ${token}`}})
      success++
    }catch{}
  }
  ElMessage.success(`已设置${success}个接口优先级为${setPriorityValue.value}`)
  priorityDialogVisible.value=false
  setPriorityValue.value=''
  loadInterfaces()
}

const addToChain = (row:IF) => {chainInterfaces.value.push({...row,var_name:''});ElMessage.success(`已添加${row.name}`)}
const handleExecuteChain = async () => {
  if(!chainInterfaces.value.length){ElMessage.warning('请添加接口');return}
  executing.value=true
  try{const token=localStorage.getItem('token')
    const res = await axios.post('/api/interfaces/execute-chain',{interfaces:chainInterfaces.value.map(i=>({name:i.name,method:i.method,url:i.url,headers:i.headers,params:i.params,body:i.body,body_type:i.body_type||'json',var_name:i.var_name}))},{headers:{Authorization:`Bearer ${token}`}})
    if(res.data.results?.length){
      const ok=res.data.summary?.success||0;const tot=res.data.summary?.total||res.data.results.length
      ElMessage.success(`完成: ${ok}/${tot}成功`)
      responseResult.value={results:res.data.results,summary:res.data.summary,elapsed_ms:res.data.results.reduce((s:number,r:any)=>s+(r.result?.elapsed_ms||0),0)}
      expandedResults.value=[0]
    }
  }catch(e:any){ElMessage.error(`失败: ${e.message}`)}
  finally{executing.value=false;chainDialogVisible.value=false}
}

const loadSavedChains = async () => {try{const token=localStorage.getItem('token');const r=await axios.get('/api/test-suites/?project_id=1',{headers:{Authorization:`Bearer ${token}`}});savedChains.value=Array.isArray(r.data)?r.data.map((c:any)=>({id:c.id,name:c.name,project_id:c.project_id,collection_id:c.collection_id})):[]}catch{savedChains.value=[]}}
const loadSavedChain = async (id:number) => {try{const token=localStorage.getItem('token');const r=await axios.get(`/api/test-suites/${id}/items`,{headers:{Authorization:`Bearer ${token}`}});if(r.data){chainInterfaces.value=r.data.map((s:any)=>({id:s.interface_id,name:s.name,method:s.method,url:s.url,headers:s.headers,params:s.params,body:s.body,body_type:s.body_type}));ElMessage.success('已加载测试集')}}catch(e:any){ElMessage.error(`加载失败: ${e.message}`)}}
const handleSaveChain = async () => {
  if(!chainName.value.trim()){ElMessage.warning('请输入名称');return}
  try{
    const token=localStorage.getItem('token')
    // 保存为测试集，包含接口集合信息
    await axios.post('/api/test-suites/',{
      project_id:1,
      name:chainName.value,
      description:`接口链测试集，包含 ${chainInterfaces.value.length} 个接口`,
      suite_type:'chain',
      collection_id:selectedCollectionId.value || null,
      items:chainInterfaces.value.map(i=>({interface_id:i.id,name:i.name,method:i.method,url:i.url,headers:i.headers,params:i.params,body:i.body,body_type:i.body_type}))
    },{headers:{Authorization:`Bearer ${token}`}})
    ElMessage.success('已保存为测试集');chainName.value='';chainDialogVisible.value=false
  }catch(e:any){ElMessage.error(`失败: ${e.message}`)}
}

const toggleExpand = (idx:number) => {const i=expandedResults.value.indexOf(idx);i>-1?expandedResults.value.splice(i,1):expandedResults.value.push(idx)}

const handleImportSuccess = (r:any) => {ElMessage.success(`导入成功`);loadInterfaces();importDialogVisible.value=false}
const handleImportError = () => {ElMessage.error('导入失败')}

// 导出 - 优先导出选中的，否则导出当前搜索结果
const handleExport = () => {
  const data = (selectedRows.value.length ? selectedRows.value : interfaces.value).map(i=>({name:i.name,method:i.method,url:i.url,description:i.description,body_type:i.body_type||'json',headers:i.headers,params:i.params,body:i.body}))
  const count = selectedRows.value.length || interfaces.value.length
  const b=new Blob([JSON.stringify(data,null,2)],{type:'application/json'})
  const u=URL.createObjectURL(b);const a=document.createElement('a');a.href=u;a.download=`interfaces_${new Date().toISOString().slice(0,10)}_${count}个.json`;a.click();URL.revokeObjectURL(u);ElMessage.success(`导出成功: ${count}个接口`)
}
const handleDownloadTemplate = async (fmt:string) => {try{const token=localStorage.getItem('token');const r=await axios.get(`/api/interfaces/template?format=${fmt}`,{headers:{Authorization:`Bearer ${token}`},responseType:'blob'});const u=URL.createObjectURL(new Blob([r.data]));const a=document.createElement('a');a.href=u;a.download=`template.${fmt==='yaml'?'yaml':fmt}`;a.click();URL.revokeObjectURL(u);ElMessage.success('模板下载成功')}catch{ElMessage.error('模板下载失败')}}

// 报告 - 生成选中或全部接口的报告
const handleGenerateReport = () => {
  const ifs = selectedRows.value.length ? selectedRows.value : interfaces.value
  const d={title:'接口测试报告',generatedAt:new Date().toLocaleString(),total:ifs.length,interfaces:ifs.map(i=>({name:i.name,method:i.method,url:i.url,status:i.last_status_code===200?'PASS':i.last_status_code?'FAIL':'NOT_RUN',time:i.last_response_time}))}
  const passCount = ifs.filter(i=>i.last_status_code===200).length
  const html=`<!DOCTYPE html><html><head><meta charset="UTF-8"><title>${d.title}</title><style>body{font-family:Arial;padding:20px;background:#f5f5f5}.h{background:linear-gradient(135deg,#409EFF,#722ed1);color:#fff;padding:30px;border-radius:8px}.s{display:flex;gap:20px}.c{background:#fff;padding:20px;border-radius:8px;flex:1;text-align:center;box-shadow:0 2px 8px rgba(0,0,0,0.1)}.c h2{margin:0;font-size:32px}table{width:100%;background:#fff;border-radius:8px;overflow:hidden;box-shadow:0 2px 8px}th{background:#409EFF;color:#fff;padding:12px;text-align:left}td{padding:12px;border-bottom:1px solid #f0f0f0}.PASS{color:#67C23A}.FAIL{color:#F56C6C}<\/style></head><body><div class="h"><h1>📊 ${d.title}</h1><p>生成时间: ${d.generatedAt}</p></div><div class="s"><div class="c"><h2>${d.total}</h2><p>总接口</p></div><div class="c"><h2 style="color:#67C23A">${passCount}</h2><p>通过</p></div><div class="c"><h2 style="color:#F56C6C">${d.total-passCount}</h2><p>失败</p></div></div><table><thead><tr><th>名称</th><th>方法</th><th>URL</th><th>状态</th></tr></thead><tbody>${d.interfaces.map(i=>`<tr><td>${i.name}</td><td>${i.method}</td><td>${i.url}</td><td class="${i.status}">${i.status}</td></tr>`).join('')}</tbody></table></body></html>`
  const b=new Blob([html],{type:'text/html'});const u=URL.createObjectURL(b);const a=document.createElement('a');a.href=u;a.download=`report_${new Date().toISOString().slice(0,10)}_${ifs.length}个.html`;a.click();URL.revokeObjectURL(u);ElMessage.success(`报告已生成: ${ifs.length}个接口`)
}

onMounted(() => {loadInterfaces()})
</script>

<style scoped>
.json-path-item:hover { background: #f0f7ff; }
.interface-execute{padding:20px}
.header{display:flex;justify-content:space-between;align-items:center;margin-bottom:20px}
.header h1{margin:0;font-size:24px;color:#303133}
.header-actions{display:flex;gap:12px}
.request-line{display:flex;gap:12px;margin-bottom:16px}
.param-row{display:flex;align-items:center;gap:8px;margin-bottom:8px}
.assertion-box{margin-top:16px;padding:12px;background:#fafafa;border-radius:4px}
.assertion-title{font-weight:bold;margin-bottom:8px}
.list-toolbar{display:flex;gap:8px;margin-bottom:12px}
.interface-list-card{height:calc(100vh - 280px)}
.chain-item-row{display:flex;align-items:center;gap:8px;padding:8px;background:#f5f5f5;border-radius:4px;margin-bottom:6px}
.empty-chain{text-align:center;color:#999;padding:20px}
.response-card{min-height:300px}
.empty-response{color:#909399;text-align:center;padding:40px}
.response-pre{background:#1e1e1e;color:#d4d4d4;padding:12px;border-radius:4px;overflow:auto;max-height:400px;font-size:12px;margin:0;cursor:pointer}
.response-pre:hover{opacity:0.9;border:1px solid #409eff}
.result-meta{margin-bottom:8px;display:flex;gap:8px}
.chain-item{background:#f6ffed}
.chain-item.fail{background:#fff2f0}
.chain-summary{padding:8px;background:#e6f7ff;border-radius:4px;text-align:center;display:flex;gap:8px;justify-content:center}
.header{display:flex;justify-content:space-between;align-items:center;margin-bottom:20px}
.header h1{margin:0;font-size:24px;color:#303133}
.header-actions{display:flex;gap:12px}
.request-line{display:flex;gap:12px;margin-bottom:16px}
.param-row{display:flex;align-items:center;gap:8px;margin-bottom:8px}
.assertion-box{margin-top:16px;padding:12px;background:#fafafa;border-radius:4px}
.assertion-title{font-weight:bold;margin-bottom:8px}
.list-toolbar{display:flex;gap:8px;margin-bottom:12px}
.interface-list-card{height:calc(100vh - 280px)}
.chain-item-row{display:flex;align-items:center;gap:8px;padding:8px;background:#f5f5f5;border-radius:4px;margin-bottom:6px}
.empty-chain{text-align:center;color:#999;padding:20px}
.response-card{min-height:300px}
.empty-response{color:#909399;text-align:center;padding:40px}
.response-pre{background:#1e1e1e;color:#d4d4d4;padding:12px;border-radius:4px;overflow:auto;max-height:400px;font-size:12px;margin:0;cursor:pointer}
.response-pre:hover{opacity:0.9;border:1px solid #409eff}
.result-meta{margin-bottom:8px;display:flex;gap:8px}
.chain-item{background:#f6ffed}
.chain-item.fail{background:#fff2f0}
.chain-summary{padding:8px;background:#e6f7ff;border-radius:4px;text-align:center;display:flex;gap:8px;justify-content:center}
.json-path-item:hover { background: #f0f7ff; }
</style>
