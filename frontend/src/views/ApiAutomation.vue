/**
 * 接口自动化测试平台 - 增强版
 * 包含：手动测试、接口管理、测试集管理、测试执行报告
 */
import { useState, useEffect } from 'react'
import { Card, Tabs, Form, Input, Select, Button, Space, Table, Tag, message, Row, Col, Tooltip, Modal, Upload, Popconfirm, Badge, Dropdown } from 'antd'
import { PlayCircleOutlined, SaveOutlined, QuestionCircleOutlined, SwapOutlined, UploadOutlined, DownloadOutlined, DeleteOutlined, PlusOutlined, ExperimentOutlined, FileTextOutlined, StarOutlined, StarFilled, SettingOutlined, CopyOutlined, ArrowUpOutlined, ArrowDownOutlined } from '@ant-design/icons'
import { API_BASE_URL } from '../utils/api'
  id?: number
  name: string
  method: string
  url: string
  description?: string
  headers?: Record<string, string>
  params?: Record<string, string>
  body?: Record<string, unknown>
  body_type?: string
  is_favorite?: boolean
  lastResult?: any
  lastExecuteTime?: number
  last_status_code?: number
  last_response_time?: number
  last_response_body?: string
  last_executed_at?: string
  assertions?: {type: string, expected: any}[]
  var_name?: string  // 接口链中用于提取变量的名称
}

interface KeyValuePair {
  key: string
  value: string
  enabled: boolean
}

type ResponseResult = {
  interface?: { id: number; name: string; method: string; url: string }
  result?: { status_code: number; headers: Record<string, string>; body: unknown; elapsed_ms: number; error?: string }
  summary?: { total: number; success: number; failed: number }
  results?: Array<{ interface: string; result: { status_code: number; body: unknown } }>
}

export default function ApiAutomation() {
  const [requestForm] = Form.useForm()
  const [interfaces, setInterfaces] = useState<InterfaceData[]>([])
  const [chainModalVisible, setChainModalVisible] = useState(false)
  const [chainInterfaces, setChainInterfaces] = useState<InterfaceData[]>([])
  const [savedChains, setSavedChains] = useState<{id: number, name: string}[]>([])
  const [chainName, setChainName] = useState('')
  const [importModalVisible, setImportModalVisible] = useState(false)
  const [showFavoritesOnly, setShowFavoritesOnly] = useState(false)
  const [searchText, setSearchText] = useState('')
  const [loading, setLoading] = useState(false)
  const [interfacesLoading, setInterfacesLoading] = useState(false)
  const [selectedRowKeys, setSelectedRowKeys] = useState<React.Key[]>([])
  const [responseResult, setResponseResult] = useState<ResponseResult | null>(null)
  const [expandedResults, setExpandedResults] = useState<number[]>([])
  const [resultTab, setResultTab] = useState<{[key: number]: 'body' | 'headers'}> ({})
  const [responseHistory, setResponseHistory] = useState<{time: string, data: any}[]>([])
  const [compareMode, setCompareMode] = useState(false)
  const [activeTab, setActiveTab] = useState('manual')
  const [pagination, setPagination] = useState({ current: 1, pageSize: 20, total: 0 })
  
  // form-data 和文件上传状态
  const [bodyType, setBodyType] = useState('json')
  const [formDataParams, setFormDataParams] = useState<KeyValuePair[]>([{ key: '', value: '', enabled: true }])
  const [uploadFiles, setUploadFiles] = useState<any[]>([])
  const [assertions, setAssertions] = useState<{type: string, expected: any}[]>([])

  // 加载接口列表
  const loadInterfaces = async (page = 1, pageSize = 10) => {
    setInterfacesLoading(true)
    try {
      const offset = (page - 1) * pageSize
      const searchParam = searchText ? `&search=${encodeURIComponent(searchText)}` : ''
      const url = showFavoritesOnly 
        ? `${API_BASE_URL}/api/interfaces/?favorites_only=true&limit=${pageSize}&offset=${offset}${searchParam}`
        : `${API_BASE_URL}/api/interfaces/?limit=${pageSize}&offset=${offset}${searchParam}`
      const response = await fetch(url)
      
      if (response.status === 401) {
        message.error('请先登录')
        setInterfaces([])
        return
      }
      
      const data = await response.json()
      // 支持分页返回格式
      if (Array.isArray(data)) {
        setInterfaces(data)
        setPagination((prev: any) => ({ ...prev, current: page, pageSize, total: data.length }))
      } else if (data.items) {
        setInterfaces(data.items)
        setPagination((prev: any) => ({ ...prev, current: page, pageSize, total: data.total || data.items.length }))
      } else {
        setInterfaces([])
      }
    } catch (error) {
      console.error('Failed to load interfaces:', error)
      setInterfaces([])
    } finally {
      setInterfacesLoading(false)
    }
  }

  // 分页变化
  const handlePageChange = (page: number, pageSize: number) => {
    loadInterfaces(page, pageSize)
  }

  useEffect(() => {
    loadInterfaces(pagination.current, pagination.pageSize)
  }, [showFavoritesOnly, searchText])

  // 发送请求
  const handleSend = async () => {
    try {
      const values = await requestForm.validateFields()
    
    // 验证 URL
    if (!values.url) {
      message.error('请输入请求 URL')
      return
    }
    
    setLoading(true)
    setResponseResult(null)
    
    try {
      let requestBody: any = {}
      let headers: any = {}
      let params: any = {}
      
      // 解析 headers
      if (values.headers) {
        try { headers = JSON.parse(values.headers) } catch {}
      }
      
      // 解析 params  
      if (values.params) {
        try { params = JSON.parse(values.params) } catch {}
      }
      
      // 根据 body_type 处理 body
      if (bodyType === 'json' && values.body) {
        try { requestBody = JSON.parse(values.body) } catch {}
      } else if (bodyType === 'form-data') {
        formDataParams.forEach(p => {
          if (p.enabled && p.key) {
            requestBody[p.key] = p.value
          }
        })
      } else if (bodyType === 'x-www-form-urlencoded') {
        formDataParams.forEach(p => {
          if (p.enabled && p.key) {
            requestBody[p.key] = p.value
          }
        })
      }
      
      // 处理文件上传
      if (bodyType === 'file' || (uploadFiles.length > 0 && bodyType === 'form-data')) {
        const formData = new FormData()
        formData.append('file', uploadFiles[0])
        
        const response = await fetch(`${API_BASE_URL}/api/interfaces/execute`, {
          method: 'POST',
          body: formData
        })
        const result = await response.json()
        setResponseResult(result);
        setResponseHistory(prev => [{
          time: new Date().toLocaleTimeString(),
          data: result
        }, ...prev.slice(0, 9)])
        message.success('请求已发送！')
        return
      }
      
      // 普通请求 - 使用直接执行 API
      const startTime = Date.now()
      const response = await fetch(`${API_BASE_URL}/api/interfaces/execute-direct`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          method: values.method,
          url: values.url,
          headers,
          params,
          body: requestBody,
          body_type: bodyType,
          assertions
        })
      })
      const result = await response.json()
      const elapsed = Date.now() - startTime
      setResponseResult({ ...result, elapsed_ms: elapsed })
      message.success(`请求已发送！耗时: ${elapsed}ms`)
    } catch (error: any) {
      message.error(`请求失败: ${error.message}`)
    } finally {
      setLoading(false)
    }
    } catch (error) {
      // 表单验证失败，忽略
    }
  }

  const handleSave = async () => {
    const values = requestForm.getFieldsValue()
    try {
      let bodyData: any = values.body || {}
      
      if (bodyType === 'form-data' || bodyType === 'x-www-form-urlencoded') {
        const obj: Record<string, string> = {}
        formDataParams.forEach(p => {
          if (p.enabled && p.key) {
            obj[p.key] = p.value
          }
        })
        bodyData = obj
      }
      
      const data = {
        name: values.name || '未命名接口',
        method: values.method || 'GET',
        url: values.url || '',
        description: values.description || '',
        headers: values.headers ? JSON.parse(values.headers || '{}') : {},
        params: values.params ? JSON.parse(values.params || '{}') : {},
        body: bodyData,
        body_type: bodyType
      }
      
      if (values.id) {
        await fetch(`${API_BASE_URL}/api/interfaces/${values.id}`, {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(data)
        })
        message.success('接口已更新')
      } else {
        await fetch(`${API_BASE_URL}/api/interfaces/`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ ...data, project_id: 1 })
        })
        message.success('接口已保存')
      }
      loadInterfaces()
    } catch (error: any) {
      message.error(`保存失败: ${error.message}`)
    }
  }

  // 导入接口
  const handleImport = async (file: File) => {
    const formData = new FormData()
    formData.append('file', file)
    
    try {
      const response = await fetch(`${API_BASE_URL}/api/interfaces/import?project_id=1`, {
        method: 'POST',
        body: formData
      })
      const result = await response.json()
      message.success(result.message || '导入成功')
      loadInterfaces()
      setImportModalVisible(false)
    } catch (error: any) {
      message.error(`导入失败: ${error.message}`)
    }
    return false
  }

  // 导出接口
  const handleExport = () => {
    const exportData = interfaces.map(i => ({
      name: i.name,
      method: i.method,
      url: i.url,
      description: i.description,
      body_type: i.body_type || 'json',
      headers: i.headers,
      params: i.params,
      body: i.body
    }))
    
    const blob = new Blob([JSON.stringify(exportData, null, 2)], { type: 'application/json' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `interfaces_${new Date().toISOString().slice(0,10)}.json`
    a.click()
    URL.revokeObjectURL(url)
    message.success('导出成功')
  }

  // 生成测试报告
  const handleGenerateReport = () => {
    const reportData = {
      title: '接口自动化测试报告',
      generatedAt: new Date().toLocaleString(),
      summary: {
        total: interfaces.length,
        withResults: interfaces.filter(i => i.last_status_code).length,
        passRate: (interfaces.filter(i => i.last_status_code === 200).length / interfaces.filter(i => i.last_status_code).length * 100) || 0
      },
      interfaces: interfaces.map(i => ({
        name: i.name,
        method: i.method,
        url: i.url,
        lastStatus: i.last_status_code,
        lastResponseTime: i.last_response_time,
        lastExecutedAt: i.last_executed_at,
        status: i.last_status_code === 200 ? 'PASS' : i.last_status_code ? 'FAIL' : 'NOT_RUN'
      }))
    }
    
    const htmlReport = `<!DOCTYPE html><html><head><meta charset="UTF-8"><title>接口测试报告</title><style>
body{font-family:Arial,sans-serif;padding:20px;background:#f5f5f5}
.header{background:linear-gradient(135deg,#1890ff,#722ed1);color:#fff;padding:30px;border-radius:8px;margin-bottom:24px}
.summary{display:flex;gap:20px;margin-bottom:24px}
.summary-card{background:#fff;padding:20px;border-radius:8px;flex:1;text-align:center;box-shadow:0 2px 8px rgba(0,0,0,0.1)}
.summary-card h2{margin:0;font-size:32px}
.summary-card p{margin:8px 0 0;color:#666}
table{width:100%;background:#fff;border-radius:8px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,0.1)}
th{background:#1890ff;color:#fff;padding:12px;text-align:left}
td{padding:12px;border-bottom:1px solid #f0f0f0}
.pass{color:#52c41a;font-weight:bold}
.fail{color:#ff4d4f;font-weight:bold}
.not-run{color:#999}
</style></head><body>
<div class="header"><h1>📊 接口自动化测试报告</h1><p>生成时间: ${reportData.generatedAt}</p></div>
<div class="summary">
<div class="summary-card"><h2>${reportData.summary.total}</h2><p>总接口数</p></div>
<div class="summary-card"><h2>${reportData.summary.withResults}</h2><p>已执行</p></div>
<div class="summary-card"><h2 style="color:#52c41a">${reportData.summary.passRate.toFixed(1)}%</h2><p>通过率</p></div>
</div>
<table><thead><tr><th>接口名称</th><th>方法</th><th>URL</th><th>状态码</th><th>耗时</th><th>结果</th></tr></thead><tbody>
${reportData.interfaces.map(i => `<tr><td>${i.name}</td><td>${i.method}</td><td style="max-width:300px;overflow:hidden;text-overflow:ellipsis">${i.url}</td><td>${i.lastStatus || '-'}</td><td>${i.lastResponseTime ? i.lastResponseTime + 'ms' : '-'}</td><td class="${i.status.toLowerCase()}">${i.status}</td></tr>`).join('')}
</tbody></table></body></html>`
    
    const blob = new Blob([htmlReport], { type: 'text/html' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `test_report_${new Date().toISOString().slice(0,10)}.html`
    a.click()
    URL.revokeObjectURL(url)
    message.success('报告已生成！')
  }

  // 下载模板
  const downloadTemplate = async (format: 'excel' | 'json' | 'yaml') => {
    try {
      const response = await fetch(`${API_BASE_URL}/api/interfaces/template?format=${format}`)
      const blob = await response.blob()
      const url = URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = `interface_template.${format === 'yaml' ? 'yaml' : format}`
      a.click()
      URL.revokeObjectURL(url)
      message.success('模板下载成功')
    } catch (error) {
      message.error('模板下载失败')
    }
  }

  // 切换收藏
  const toggleFavorite = async (id: number, current: boolean) => {
    try {
      await fetch(`${API_BASE_URL}/api/interfaces/${id}/favorite`, { method: 'PATCH' })
      loadInterfaces()
    } catch (error) {
      message.error('操作失败')
    }
  }

  // 批量删除
  const handleBatchDelete = async () => {
    if (selectedRowKeys.length === 0) {
      message.warning('请选择要删除的接口')
      return
    }
    
    try {
      for (const id of selectedRowKeys) {
        await fetch(`${API_BASE_URL}/api/interfaces/${id}`, { method: 'DELETE' })
      }
      message.success(`已删除 ${selectedRowKeys.length} 个接口`)
      setSelectedRowKeys([])
      loadInterfaces()
    } catch (error: any) {
      message.error(`删除失败: ${error.message}`)
    }
  }

  // 批量执行
  const handleBatchExecute = async () => {
    if (selectedRowKeys.length === 0) {
      message.warning('请选择要执行的接口')
      return
    }
    
    const selectedInterfaces = interfaces.filter(i => selectedRowKeys.includes(i.id!))
    if (selectedInterfaces.length === 0) {
      message.warning('未找到选中的接口')
      return
    }
    
    setLoading(true)
    const results: any[] = []
    
    try {
      for (const iface of selectedInterfaces) {
        try {
          const response = await fetch(`${API_BASE_URL}/api/interfaces/execute-direct`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              method: iface.method,
              url: iface.url,
              headers: typeof iface.headers === 'string' ? JSON.parse(iface.headers) : iface.headers,
              params: typeof iface.params === 'string' ? JSON.parse(iface.params) : iface.params,
              body: typeof iface.body === 'string' ? JSON.parse(iface.body) : iface.body,
              body_type: iface.body_type || 'json',
              interface_id: iface.id,
              save_result: true
            })
          })
          const result = await response.json()
          results.push({ name: iface.name, ...result })
        } catch (e) {
          results.push({ name: iface.name, error: e.message })
        }
      }
      
      const successCount = results.filter(r => r.passed).length
      message.success(`批量执行完成: ${successCount}/${results.length} 成功`)
      
      // 显示结果
      setResponseResult({
        batch_results: results,
        summary: { total: results.length, success: successCount, failed: results.length - successCount }
      })
      
      setSelectedRowKeys([])
      loadInterfaces()
    } catch (error: any) {
      message.error(`批量执行失败: ${error.message}`)
    } finally {
      setLoading(false)
    }
  }

  // 批量添加到接口链
  const handleBatchAddToChain = () => {
    if (selectedRowKeys.length === 0) {
      message.warning('请选择要添加到链的接口')
      return
    }
    const selectedInterfaces = interfaces.filter(i => selectedRowKeys.includes(i.id!))
    if (selectedInterfaces.length === 0) {
      message.warning('未找到选中的接口')
      return
    }
    setChainInterfaces([...chainInterfaces, ...selectedInterfaces])
    message.success(`已添加 ${selectedInterfaces.length} 个接口到执行链`)
    setSelectedRowKeys([])
  }

  const handleExecuteChain = async () => {
    if (chainInterfaces.length === 0) {
      message.warning('请先添加接口到执行链')
      return
    }
    
    setLoading(true)
    try {
      const response = await fetch(`${API_BASE_URL}/api/interfaces/execute-chain`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          interfaces: chainInterfaces.map(i => ({
            name: i.name,
            method: i.method,
            url: i.url,
            headers: typeof i.headers === 'string' ? JSON.parse(i.headers) : i.headers,
            params: typeof i.params === 'string' ? JSON.parse(i.params) : i.params,
            body: typeof i.body === 'string' ? JSON.parse(i.body) : i.body,
            body_type: i.body_type || 'json',
            var_name: i.var_name || undefined
          }))
        })
      })
      const result = await response.json()
      
      // 显示结果
      if (result.results && result.results.length > 0) {
        const successCount = result.summary?.success || 0
        const totalCount = result.summary?.total || result.results.length
        message.success(`执行完成: ${successCount}/${totalCount} 成功`)
        
        // 显示每个接口的结果
        const resultsText = result.results.map((r: any, idx: number) => {
          const status = r.result?.status_code
          const name = r.name || `接口${idx + 1}`
          return `${name}: ${status === 200 ? '✅' : '❌'} ${status}`
        }).join('\n')
        
        // 在响应区域显示
        setResponseResult({
          summary: result.summary,
          results: result.results,
          elapsed_ms: result.results.reduce((sum: number, r: any) => sum + (r.result?.elapsed_ms || 0), 0)
        })
        // 默认展开第一个接口的详情，并设置默认标签为 body
        setExpandedResults([0])
        setResultTab({ 0: 'body' })
      } else {
        message.warning('执行完成但无结果')
      }
      
      console.log('Chain result:', result)
    } catch (error: any) {
      message.error(`执行失败: ${error.message}`)
    } finally {
      setLoading(false)
    }
    setChainModalVisible(false)
  }

  const addToChain = (record: InterfaceData) => {
    setChainInterfaces([...chainInterfaces, { ...record }])
    message.success(`已将 ${record.name} 添加到执行链`)
  }

  const removeFromChain = (index: number) => {
    const newChain = [...chainInterfaces]
    newChain.splice(index, 1)
    setChainInterfaces(newChain)
  }

  // 保存接口链
  const handleSaveChain = async () => {
    if (!chainName.trim()) {
      message.warning('请输入接口链名称')
      return
    }
    try {
      const response = await fetch(`${API_BASE_URL}/api/chains/`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          project_id: 1,
          name: chainName,
          steps: chainInterfaces.map(i => ({
            interface_id: i.id,
            name: i.name,
            method: i.method,
            url: i.url,
            headers: i.headers,
            params: i.params,
            body: i.body,
            body_type: i.body_type,
            var_name: i.var_name
          }))
        })
      })
      if (response.ok) {
        message.success('接口链保存成功')
        setChainName('')
        loadSavedChains()
      }
    } catch (error: any) {
      message.error(`保存失败: ${error.message}`)
    }
  }

  // 加载已保存的接口链列表
  const loadSavedChains = async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/api/chains/?project_id=1`)
      const data = await response.json()
      // 提取 id 和 name 字段
      const chains = Array.isArray(data) ? data.map((c: any) => ({ id: c.id, name: c.name })) : []
      setSavedChains(chains)
    } catch (error) {
      console.error('Failed to load chains:', error)
    }
  }

  // 加载选中的接口链
  const handleLoadChain = async (chainId: number) => {
    try {
      const response = await fetch(`${API_BASE_URL}/api/chains/${chainId}`)
      const chain = await response.json()
      if (chain.steps) {
        setChainInterfaces(chain.steps.map((s: any) => ({
          id: s.interface_id,
          name: s.name,
          method: s.method,
          url: s.url,
          headers: s.headers,
          params: s.params,
          body: s.body,
          body_type: s.body_type,
          var_name: s.var_name
        })))
        message.success('接口链加载成功')
      }
    } catch (error: any) {
      message.error(`加载失败: ${error.message}`)
    }
  }

  const moveChainItem = (index: number, direction: number) => {
    const newChain = [...chainInterfaces]
    const targetIndex = index + direction
    if (targetIndex < 0 || targetIndex >= newChain.length) return
    const temp = newChain[index]
    newChain[index] = newChain[targetIndex]
    newChain[targetIndex] = temp
    setChainInterfaces(newChain)
  }

  // form-data 相关函数
  const addFormDataParam = () => {
    setFormDataParams([...formDataParams, { key: '', value: '', enabled: true }])
  }

  const updateFormDataParam = (index: number, field: keyof KeyValuePair, value: string | boolean) => {
    const newParams: KeyValuePair[] = [...formDataParams]
    newParams[index] = { ...newParams[index], [field]: value }
    setFormDataParams(newParams)
  }

  const removeFormDataParam = (index: number) => {
    const newParams = formDataParams.filter((_, i) => i !== index)
    setFormDataParams(newParams)
  }

  // 文件上传变化
  const handleFileChange = (info: any) => {
    setUploadFiles(info.fileList.slice(-1))
  }

  const columns = [
    { title: '名称', dataIndex: 'name', key: 'name', width: 180,
      render: (name: string, record: InterfaceData) => (
        <div style={{ display: 'flex', flexDirection: 'column' }}>
          <span style={{ fontWeight: 500 }}>{name}</span>
          {record.description && <span style={{ fontSize: 11, color: '#888' }}>{record.description.substring(0, 30)}</span>}
        </div>
      )
    },
    { title: '收藏', dataIndex: 'is_favorite', key: 'favorite', width: 50,
      render: (favorite: boolean, record: InterfaceData) => (
        <Button 
          type="text" 
          size="small"
          icon={favorite ? <StarFilled style={{ color: '#faad14' }} /> : <StarOutlined />}
          onClick={(e) => { e.stopPropagation(); record.id && toggleFavorite(record.id, favorite || false) }}
        />
      )
    },
    { title: '方法', dataIndex: 'method', key: 'method', width: 70,
      render: (method: string) => {
        const colorMap: Record<string, string> = { GET: 'green', POST: 'blue', PUT: 'orange', DELETE: 'red', PATCH: 'purple' }
        return <Tag color={colorMap[method] || 'default'}>{method}</Tag>
      }
    },
    { title: 'URL', dataIndex: 'url', key: 'url', ellipsis: true, width: 200 },
    { title: 'Body', dataIndex: 'body_type', key: 'body_type', width: 70,
      render: (bt: string) => <Tag>{bt || 'json'}</Tag>
    },
    { title: '耗时', key: 'elapsed', width: 70,
      render: (_: any, record: InterfaceData) => {
        const time = record.lastResult?.result?.elapsed_ms || record.last_response_time
        if (time) {
          return <Tag color="blue">{time}ms</Tag>
        }
        return <Tag>-</Tag>
      }
    },
    { title: '状态', key: 'result', width: 70,
      render: (_: any, record: InterfaceData) => {
        if (record.lastResult?.passed !== undefined) {
          return record.lastResult.passed 
            ? <Tag color="green">PASS</Tag> 
            : <Tag color="red">FAIL</Tag>
        }
        if (record.last_status_code) {
          const status = record.last_status_code
          return <Tag color={status >= 400 ? 'red' : status >= 300 ? 'orange' : 'green'}>{status}</Tag>
        }
        return <Tag>-</Tag>
      }
    },
    { title: '操作', key: 'action', width: 180,
      render: (_: any, record: InterfaceData) => {
        const handleEdit = () => {
          const editData = {
            ...record,
            headers: record.headers ? (typeof record.headers === 'string' ? record.headers : JSON.stringify(record.headers, null, 2)) : '',
            params: record.params ? (typeof record.params === 'string' ? record.params : JSON.stringify(record.params, null, 2)) : '',
            body: record.body ? (typeof record.body === 'string' ? record.body : JSON.stringify(record.body, null, 2)) : '',
            name: record.name || '',
            url: record.url || '',
            method: record.method || 'GET',
            description: record.description || '',
            body_type: record.body_type || 'json'
          }
          requestForm.setFieldsValue(editData)
          setBodyType(record.body_type || 'json')
        }
        const handleCopy = () => {
          const copyData = {
            ...record,
            headers: record.headers ? (typeof record.headers === 'string' ? record.headers : JSON.stringify(record.headers, null, 2)) : '',
            params: record.params ? (typeof record.params === 'string' ? record.params : JSON.stringify(record.params, null, 2)) : '',
            body: record.body ? (typeof record.body === 'string' ? record.body : JSON.stringify(record.body, null, 2)) : '',
            name: (record.name || '') + '_副本',
            url: record.url || '',
            method: record.method || 'GET',
            description: record.description || '',
            body_type: record.body_type || 'json'
          }
          requestForm.setFieldsValue(copyData)
          setBodyType(record.body_type || 'json')
          message.success('已复制接口，请修改名称后保存')
        }
        return (
        <Space size="small">
          <Button type="link" size="small" onClick={handleEdit}>编辑</Button>
          <Button type="link" size="small" icon={<CopyOutlined />} onClick={handleCopy} title="复制" />
          <Button type="link" size="small" icon={<PlayCircleOutlined />} onClick={() => handleExecuteInterface(record)}>执行</Button>
          <Button type="link" size="small" icon={<SwapOutlined />} onClick={() => addToChain(record)}>加链</Button>
        </Space>
      )}
    },
  ]

  const handleExecuteInterface = async (record: InterfaceData) => {
    try {
      const response = await fetch(`${API_BASE_URL}/api/interfaces/execute-direct`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          method: record.method,
          url: record.url,
          headers: record.headers,
          params: record.params,
          body: record.body,
          body_type: record.body_type || 'json',
          assertions: record.assertions || [],
          interface_id: record.id,
          save_result: true
        })
      })
      const result = await response.json()
      // 更新接口的最后执行结果和时间
      setInterfaces(interfaces.map(i => 
        i.id === record.id ? { ...i, lastResult: result, lastExecuteTime: Date.now(), last_status_code: result.result?.status_code, last_response_time: result.result?.elapsed_ms } : i
      ))
      // 同时显示响应结果在界面上
      setResponseResult(result.result)
      const passed = result.passed
      message.success(`接口 ${record.name} 执行${passed ? '通过' : '失败'}`)
      // 延迟刷新以获取持久化数据
      setTimeout(() => loadInterfaces(), 1500)
    } catch (error: any) {
      message.error(`执行失败: ${error.message}`)
    }
  }

  const rowSelection = { selectedRowKeys, onChange: setSelectedRowKeys }

  // 手动测试面板
  const renderManualTest = () => (
    <Row gutter={16}>
      <Col span={16}>
        <Card title="📡 接口配置" size="small" style={{ marginBottom: 12 }}>
          <Form form={requestForm} layout="vertical">
            <Row gutter={16}>
              <Col span={3}>
                <Form.Item name="method" initialValue="GET">
                  <Select>
                    <Option value="GET">GET</Option>
                    <Option value="POST">POST</Option>
                    <Option value="PUT">PUT</Option>
                    <Option value="DELETE">DELETE</Option>
                    <Option value="PATCH">PATCH</Option>
                  </Select>
                </Form.Item>
              </Col>
              <Col span={9}>
                <Form.Item name="url" rules={[{ required: true }]}>
                  <Input placeholder="请求 URL" />
                </Form.Item>
              </Col>
              <Col span={3}>
                <Form.Item name="body_type" initialValue="json">
                  <Select onChange={setBodyType}>
                    <Option value="json">JSON</Option>
                    <Option value="form-data">FormData</Option>
                    <Option value="x-www-form-urlencoded">URLEncoded</Option>
                    <Option value="file">文件上传</Option>
                    <Option value="raw">Raw</Option>
                  </Select>
                </Form.Item>
              </Col>
              <Col span={24}>
                <Form.Item name="name">
                  <Input placeholder="接口名称" />
                </Form.Item>
              </Col>
              <Col span={24}>
                <Form.Item name="description">
                  <Input placeholder="接口描述" />
                </Form.Item>
              </Col>
              <Col span={6}>
                <Form.Item>
                  <Space>
                    <Button type="primary" icon={<PlayCircleOutlined />} onClick={handleSend} loading={loading}>发送</Button>
                    <Button icon={<SaveOutlined />} onClick={handleSave}>保存</Button>
                    <Button icon={<SwapOutlined />} onClick={() => { setChainModalVisible(true); loadSavedChains(); }}>执行链</Button>
                  </Space>
                </Form.Item>
              </Col>
            </Row>

            <Tabs defaultActiveKey="params" items={[
              {
                label: 'Params',
                key: 'params',
                children: (
                  <Form.Item name="params">
                    <TextArea rows={2} placeholder='{"key": "value"}' />
                  </Form.Item>
                )
              },
              {
                label: 'Headers',
                key: 'headers',
                children: (
                  <Form.Item name="headers">
                    <TextArea rows={2} placeholder='{"Content-Type": "application/json"}' />
                  </Form.Item>
                )
              },
              {
                label: 'Body',
                key: 'body',
                children: (
                  <>
                {bodyType === 'json' && (
                  <Form.Item name="body">
                    <TextArea rows={4} placeholder='{"key": "value"}' />
                  </Form.Item>
                )}
                {bodyType === 'form-data' && (
                  <div>
                    {formDataParams.map((param, index) => (
                      <Row key={index} gutter={8} style={{ marginBottom: 8 }}>
                        <Col span={1}>
                          <input type="checkbox" checked={param.enabled} onChange={e => updateFormDataParam(index, 'enabled', e.target.checked)} />
                        </Col>
                        <Col span={8}>
                          <Input placeholder="Key" value={param.key} onChange={e => updateFormDataParam(index, 'key', e.target.value)} />
                        </Col>
                        <Col span={12}>
                          <Input placeholder="Value" value={param.value} onChange={e => updateFormDataParam(index, 'value', e.target.value)} />
                        </Col>
                        <Col span={3}>
                          <Button size="small" danger icon={<DeleteOutlined />} onClick={() => removeFormDataParam(index)} />
                        </Col>
                      </Row>
                    ))}
                    <Button type="dashed" onClick={addFormDataParam} icon={<PlusOutlined />}>添加参数</Button>
                  </div>
                )}
                {bodyType === 'x-www-form-urlencoded' && (
                  <div>
                    {formDataParams.map((param, index) => (
                      <Row key={index} gutter={8} style={{ marginBottom: 8 }}>
                        <Col span={1}>
                          <input type="checkbox" checked={param.enabled} onChange={e => updateFormDataParam(index, 'enabled', e.target.checked)} />
                        </Col>
                        <Col span={8}>
                          <Input placeholder="Key" value={param.key} onChange={e => updateFormDataParam(index, 'key', e.target.value)} />
                        </Col>
                        <Col span={12}>
                          <Input placeholder="Value" value={param.value} onChange={e => updateFormDataParam(index, 'value', e.target.value)} />
                        </Col>
                        <Col span={3}>
                          <Button size="small" danger icon={<DeleteOutlined />} onClick={() => removeFormDataParam(index)} />
                        </Col>
                      </Row>
                    ))}
                    <Button type="dashed" onClick={addFormDataParam} icon={<PlusOutlined />}>添加参数</Button>
                  </div>
                )}
                {bodyType === 'file' && (
                  <Upload beforeUpload={() => false} onChange={handleFileChange} fileList={uploadFiles} maxCount={1}>
                    <Button icon={<UploadOutlined />}>选择文件</Button>
                  </Upload>
                )}
                {bodyType === 'raw' && (
                  <Form.Item name="body">
                    <TextArea rows={4} placeholder='原始请求体' />
                  </Form.Item>
                )}
                
                {/* 断言配置 */}
                <div style={{ marginTop: 16, padding: 12, background: '#fafafa', borderRadius: 4 }}>
                  <div style={{ marginBottom: 8, fontWeight: 'bold' }}>⚠️ 断言配置</div>
                  <AssertionConfig value={assertions} onChange={setAssertions} />
                </div>
                  </>
                )
              }
            ]} />
          </Form>
        </Card>

        <Card title="📝 请求结果" size="small">
          <div style={{ marginBottom: 8 }}>
            <Space>
              <Button 
                size="small" 
                type={compareMode ? 'primary' : 'default'}
                onClick={() => setCompareMode(!compareMode)}
                disabled={responseHistory.length < 2}
              >
                对比模式
              </Button>
              {compareMode && responseHistory.length > 0 && (
                <Select 
                  size="small" 
                  style={{ width: 150 }} 
                  placeholder="选择历史记录对比"
                  onChange={(val) => {
                    // Show comparison
                    const oldResult = responseHistory[val]?.data
                    if (oldResult) {
                      setResponseResult({
                        ...responseResult,
                        _compare: oldResult,
                        _isCompare: true
                      })
                    }
                  }}
                >
                  {responseHistory.map((h, i) => (
                    <Option key={i} value={i}>{h.time}</Option>
                  ))}
                </Select>
              )}
            </Space>
          </div>
          {/* 响应结果展示 */}
          {responseResult?.results ? (
            // 接口链结果 - 分别展示每个接口
            <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
              {responseResult.results.map((r: any, idx: number) => {
                const status = r.result?.status_code
                const elapsed = r.result?.elapsed_ms
                const name = r.name || r.interface || `接口${idx + 1}`
                const isExpanded = expandedResults.includes(idx)
                return (
                  <Card 
                    key={idx} 
                    size="small"
                    style={{ background: status >= 400 ? '#fff2f0' : '#f6ffed' }}
                    title={
                      <Space>
                        <Badge count={idx + 1} style={{ backgroundColor: status >= 400 ? '#ff4d4f' : '#52c41a' }} />
                        <Tag color={status >= 400 ? 'red' : 'green'}>{status}</Tag>
                        <span>{name}</span>
                        {elapsed && <Tag color="blue">{elapsed}ms</Tag>}
                      </Space>
                    }
                    extra={
                      <Button 
                        type="link" 
                        size="small"
                        onClick={() => {
                          setExpandedResults(prev => 
                            prev.includes(idx) ? prev.filter(i => i !== idx) : [...prev, idx]
                          )
                        }}
                      >
                        {isExpanded ? '收起详情 ▲' : '查看详情 ▼'}
                      </Button>
                    }
                  >
                    {isExpanded ? (
                      <div>
                        <Space style={{ marginBottom: 8 }}>
                          <Button 
                            type={resultTab[idx] !== 'headers' ? 'primary' : 'default'} 
                            size="small"
                            onClick={() => setResultTab(prev => ({...prev, [idx]: 'body'}))}
                          >
                            Body
                          </Button>
                          <Button 
                            type={resultTab[idx] === 'headers' ? 'primary' : 'default'}
                            size="small"
                            onClick={() => setResultTab(prev => ({...prev, [idx]: 'headers'}))}
                          >
                            Headers
                          </Button>
                        </Space>
                        <pre style={{ margin: 0, color: '#d4d4d4', fontSize: 11, fontFamily: 'Monaco, Consolas, monospace', maxHeight: 300, overflow: 'auto', background: '#1e1e1e', padding: 8, borderRadius: 4 }}>
                          {resultTab[idx] === 'headers' 
                            ? JSON.stringify(r.result?.headers || {}, null, 2)
                            : JSON.stringify(r.result?.body || r.result, null, 2)
                          }
                        </pre>
                      </div>
                    ) : (
                      <div style={{ color: '#666', fontSize: 12 }}>
                        点击「查看详情」查看响应内容
                      </div>
                    )}
                  </Card>
                )
              })}
              {responseResult.summary && (
                <div style={{ padding: 8, background: '#e6f7ff', borderRadius: 4, textAlign: 'center' }}>
                  <Tag color="blue">总耗时: {responseResult.elapsed_ms}ms</Tag>
                  <Tag color="green">成功: {responseResult.summary.success}</Tag>
                  <Tag color="red">失败: {responseResult.summary.failed}</Tag>
                </div>
              )}
            </div>
          ) : responseResult ? (
            // 单个接口结果
            <div>
              <div style={{ marginBottom: 8, display: 'flex', gap: 8, alignItems: 'center' }}>
                {responseResult.result?.status_code && (
                  <Tag color={responseResult.result.status_code >= 400 ? 'red' : 'green'} style={{ fontSize: 14 }}>
                    {responseResult.result.status_code}
                  </Tag>
                )}
                {responseResult.result?.elapsed_ms && (
                  <Tag color="blue" style={{ fontSize: 14 }}>{responseResult.result.elapsed_ms}ms</Tag>
                )}
                {responseResult.passed !== undefined && (
                  <Tag color={responseResult.passed ? 'green' : 'red'} style={{ fontSize: 14 }}>
                    {responseResult.passed ? '✓ 断言通过' : '✗ 断言失败'}
                  </Tag>
                )}
              </div>
              <div style={{ background: '#1e1e1e', borderRadius: 6, padding: 12, minHeight: 150, maxHeight: 400, overflow: 'auto' }}>
                <pre style={{ margin: 0, color: '#d4d4d4', fontSize: 12, fontFamily: 'Monaco, Consolas, monospace', whiteSpace: 'pre-wrap', wordBreak: 'break-all' }}>
                  {JSON.stringify(responseResult.result?.body || responseResult, null, 2)}
                </pre>
              </div>
            </div>
          ) : (
            <div style={{ background: '#1e1e1e', borderRadius: 6, padding: 12, minHeight: 150, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <span style={{ color: '#666' }}>点击「发送」查看结果</span>
            </div>
          )}
        </Card>
      </Col>

      <Col span={8}>
        <Card 
          title={
            <Space>
              <span>📁 接口列表</span>
              <Popconfirm title="确认删除选中的接口?" onConfirm={handleBatchDelete}>
                <Button size="small" danger icon={<DeleteOutlined />} disabled={selectedRowKeys.length === 0}>
                  批量删除({selectedRowKeys.length})
                </Button>
              </Popconfirm>
              <Button size="small" type="primary" icon={<SwapOutlined />} onClick={handleBatchAddToChain} disabled={selectedRowKeys.length === 0}>
                批量加链({selectedRowKeys.length})
              </Button>
              <Button size="small" icon={<PlayCircleOutlined />} onClick={handleBatchExecute} disabled={selectedRowKeys.length === 0}>
                批量执行({selectedRowKeys.length})
              </Button>
            </Space>
          }
        >
          <Space style={{ marginBottom: 12, width: '100%', justifyContent: 'space-between' }} wrap>
            <Space wrap>
              <Button icon={<UploadOutlined />} onClick={() => setImportModalVisible(true)}>导入</Button>
              <Dropdown
                menu={{
                  items: [
                    { key: 'excel', label: 'Excel (.xlsx)', onClick: () => downloadTemplate('excel') },
                    { key: 'json', label: 'JSON', onClick: () => downloadTemplate('json') },
                    { key: 'yaml', label: 'YAML', onClick: () => downloadTemplate('yaml') },
                  ]
                }}
              >
                <Button icon={<DownloadOutlined />}>下载模板</Button>
              </Dropdown>
              <Input.Search
                placeholder="搜索接口名称/URL"
                allowClear
                style={{ width: 200 }}
                value={searchText}
                onChange={(e) => setSearchText(e.target.value)}
                onSearch={(value) => setSearchText(value)}
              />
              <Button 
                type={showFavoritesOnly ? 'primary' : 'default'}
                icon={showFavoritesOnly ? <StarFilled style={{ color: '#faad14' }} /> : <StarOutlined />}
                onClick={() => setShowFavoritesOnly(!showFavoritesOnly)}
              >
                收藏
              </Button>
            </Space>
            <Space wrap>
              <Button icon={<DownloadOutlined />} onClick={handleExport} disabled={interfaces.length === 0}>导出</Button>
              <Button type="primary" icon={<FileTextOutlined />} onClick={handleGenerateReport} disabled={interfaces.length === 0}>生成报告</Button>
            </Space>
          </Space>
          <Table
            rowSelection={rowSelection}
            columns={columns}
            dataSource={interfaces}
            size="small"
            pagination={{ 
              current: pagination.current, 
              pageSize: pagination.pageSize, 
              total: pagination.total,
              showSizeChanger: true,
              showQuickJumper: true,
              showTotal: (total) => `共 ${total} 条`,
              onChange: handlePageChange
            }}
            rowKey="id"
            loading={interfacesLoading}
            locale={{ emptyText: '暂无接口，请导入或创建' }}
            scroll={{ x: 800, y: 400 }}
          />
        </Card>

        <Card title="🔗 接口链" style={{ marginTop: 16 }}>
          {chainInterfaces.length === 0 ? (
            <div style={{ textAlign: 'center', color: '#999', padding: 20 }}>
              点击接口列表中的「链」按钮添加
            </div>
          ) : (
            <>
              {chainInterfaces.map((iface, index) => (
                <div key={index} style={{ marginBottom: 6, display: 'flex', alignItems: 'center', padding: '6px 8px', background: '#fafafa', borderRadius: 4, border: '1px solid #f0f0f0' }}>
                  <Badge count={index + 1} style={{ backgroundColor: '#1890ff', marginRight: 8 }} />
                  <Tag color={iface.method === 'GET' ? 'green' : iface.method === 'POST' ? 'blue' : iface.method === 'DELETE' ? 'red' : 'orange'} style={{ marginRight: 8 }}>{iface.method}</Tag>
                  <span style={{ flex: 1, fontSize: 13 }}>{iface.name}</span>
                  <Input 
                    size="small" 
                    placeholder="变量名(可选)" 
                    value={iface.var_name || ''}
                    onChange={(e) => {
                      const newChain = [...chainInterfaces]
                      newChain[index] = { ...newChain[index], var_name: e.target.value }
                      setChainInterfaces(newChain)
                    }}
                    style={{ width: 120, marginRight: 8 }}
                  />
                  <Space size={4}>
                    <Button size="small" type="text" icon={<ArrowUpOutlined />} disabled={index === 0} onClick={() => moveChainItem(index, -1)} />
                    <Button size="small" type="text" icon={<ArrowDownOutlined />} disabled={index === chainInterfaces.length - 1} onClick={() => moveChainItem(index, 1)} />
                    <Button size="small" type="text" danger icon={<DeleteOutlined />} onClick={() => removeFromChain(index)} />
                  </Space>
                </div>
              ))}
              <div style={{ marginTop: 12, paddingTop: 12, borderTop: '1px solid #f0f0f0' }}>
                <span style={{ fontSize: 12, color: '#888' }}>
                  变量名：用于提取响应数据，后续接口可用 &#123;&#123;变量名.response.字段&#125;&#125; 引用
                </span>
                <Button type="primary" block icon={<PlayCircleOutlined />} onClick={handleExecuteChain} loading={loading} style={{ marginTop: 8 }}>
                  执行接口链 ({chainInterfaces.length}个)
                </Button>
              </div>
            </>
          )}
        </Card>
      </Col>
    </Row>
  )

  return (
    <div>
      <h1 style={{ fontSize: 24, marginBottom: 16 }}>
        接口自动化
        <Tooltip title="配置和执行接口测试，支持导入导出、批量操作">
          <QuestionCircleOutlined style={{ marginLeft: 8, color: '#999', cursor: 'help' }} />
        </Tooltip>
      </h1>

      <Tabs activeKey={activeTab} onChange={setActiveTab} items={[
        {
          label: <span><PlayCircleOutlined /> 手动测试</span>,
          key: 'manual',
          children: renderManualTest()
        },
        {
          label: <span><ExperimentOutlined /> 测试集</span>,
          key: 'suites',
          children: <TestSuites projectId={1} />
        },
        {
          label: <span><FileTextOutlined /> 测试报告</span>,
          key: 'reports',
          children: <TestExecution projectId={1} />
        },
        {
          label: <span><SettingOutlined /> 环境管理</span>,
          key: 'environments',
          children: <Environments projectId={1} />
        }
      ]} />

      {/* 导入 Modal */}
      <Modal
        title="导入接口"
        open={importModalVisible}
        onCancel={() => setImportModalVisible(false)}
        footer={null}
      >
        <p>支持格式: Excel(.xlsx), CSV, YAML, JSON</p>
        <Upload.Dragger
          beforeUpload={handleImport}
          accept=".xlsx,.xls,.csv,.yaml,.yml,.json"
          maxCount={1}
        >
          <p className="ant-upload-drag-icon"><UploadOutlined /></p>
          <p className="ant-upload-text">点击或拖拽文件到此处上传</p>
        </Upload.Dragger>
      </Modal>

      {/* 接口链 Modal */}
      <Modal
        title="接口链配置"
        open={chainModalVisible}
        onCancel={() => setChainModalVisible(false)}
        footer={null}
        width={600}
      >
        {/* 保存的接口链列表 */}
        {savedChains.length > 0 && (
          <div style={{ marginBottom: 16 }}>
            <div style={{ marginBottom: 8, fontWeight: 500 }}>已保存的接口链：</div>
            <Space wrap>
              {savedChains.map(chain => (
                <Tag 
                  key={chain.id} 
                  color="blue" 
                  style={{ cursor: 'pointer' }}
                  onClick={() => handleLoadChain(chain.id)}
                >
                  {chain.name}
                </Tag>
              ))}
            </Space>
          </div>
        )}
        
        {chainInterfaces.length === 0 ? (
          <div style={{ textAlign: 'center', color: '#999', padding: 40 }}>
            <p>从接口列表点击「链」按钮添加接口</p>
            <p>或从上方选择已保存的接口链</p>
          </div>
        ) : (
          <div>
            <div style={{ marginBottom: 12, display: 'flex', gap: 8 }}>
              <Input 
                placeholder="输入接口链名称保存" 
                value={chainName}
                onChange={(e) => setChainName(e.target.value)}
                style={{ flex: 1 }}
              />
              <Button type="primary" onClick={handleSaveChain}>保存</Button>
            </div>
            <div style={{ marginBottom: 12, padding: 8, background: '#e6f7ff', borderRadius: 4 }}>
              <Space>
                <Tag color="blue">共 {chainInterfaces.length} 个接口</Tag>
                <span style={{ color: '#666' }}>将按顺序执行，支持变量提取</span>
              </Space>
            </div>
            {chainInterfaces.map((iface, index) => (
              <div key={index} style={{ marginBottom: 8, padding: 10, background: '#f5f5f5', borderRadius: 4 }}>
                <Space><Badge count={index + 1} style={{ backgroundColor: '#1890ff' }} /><Tag color="blue">{iface.method}</Tag><span>{iface.name}</span><span style={{ color: '#999', fontSize: 12 }}>{iface.url?.substring(0, 40)}...</span></Space>
              </div>
            ))}
            <div style={{ marginTop: 16 }}>
              <Button type="primary" block onClick={handleExecuteChain} loading={loading}>
                执行接口链 ({chainInterfaces.length}个)
              </Button>
            </div>
          </div>
        )}
      </Modal>
    </div>
  )
}
