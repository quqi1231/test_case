<template>
  <div class="test-projects">
    <div class="header">
      <h1>🧪 测试项目管理</h1>
      <div class="header-actions">
        <el-button type="primary" @click="handleCreate"><el-icon><Plus /></el-icon>新建测试项目</el-button>
      </div>
    </div>

    <el-table :data="projects" row-key="id" v-loading="loading" empty-text="暂无测试项目">
      <el-table-column prop="name" label="名称" />
      <el-table-column prop="description" label="描述" />
      <el-table-column prop="suite_count" label="测试集数">
        <template #default="{row}"><el-tag type="success">{{ row.suite_count || 0 }}</el-tag></template>
      </el-table-column>
      <el-table-column prop="status" label="状态">
        <template #default="{row}">
          <el-tag :type="row.is_enabled ? 'success' : 'info'">{{ row.is_enabled ? '启用' : '禁用' }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="created_at" label="创建时间" />
      <el-table-column label="操作" width="250">
        <template #default="{row}">
          <el-button type="primary" link @click="handleEdit(row)">编辑</el-button>
          <el-button type="primary" link @click="handleToggle(row)">{{ row.is_enabled ? '禁用' : '启用' }}</el-button>
          <el-popconfirm title="确认删除?" @confirm="handleDelete(row.id)">
            <template #reference><el-button type="danger" link>删除</el-button></template>
          </el-popconfirm>
        </template>
      </el-table-column>
    </el-table>

    <el-dialog v-model="dialogVisible" :title="editingId ? '编辑测试项目' : '新建测试项目'" width="500px">
      <el-form :model="form" label-width="80px">
        <el-form-item label="名称" required>
          <el-input v-model="form.name" placeholder="测试项目名称" />
        </el-form-item>
        <el-form-item label="描述">
          <el-input v-model="form.description" type="textarea" placeholder="测试项目描述" />
        </el-form-item>
        <el-form-item label="启用">
          <el-switch v-model="form.is_enabled" />
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
import { ref, reactive, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { Plus } from '@element-plus/icons-vue'
import axios from 'axios'

interface TestProject {
  id: number
  name: string
  description?: string
  project_id: number
  suite_count?: number
  is_enabled: boolean
  created_at?: string
}

const loading = ref(false)
const projects = ref<TestProject[]>([])
const dialogVisible = ref(false)
const editingId = ref<number | null>(null)
const form = reactive({
  name: '',
  description: '',
  is_enabled: true
})

const loadProjects = async () => {
  loading.value = true
  try {
    const token = localStorage.getItem('token')
    const res = await axios.get('/api/test-projects/', {
      headers: { Authorization: `Bearer ${token}` }
    })
    projects.value = Array.isArray(res.data) ? res.data : []
  } catch (e: any) {
    ElMessage.error(`加载失败: ${e.message}`)
    projects.value = []
  } finally {
    loading.value = false
  }
}

const handleCreate = () => {
  editingId.value = null
  form.name = ''
  form.description = ''
  form.is_enabled = true
  dialogVisible.value = true
}

const handleEdit = (row: TestProject) => {
  editingId.value = row.id
  form.name = row.name
  form.description = row.description || ''
  form.is_enabled = row.is_enabled
  dialogVisible.value = true
}

const handleSave = async () => {
  if (!form.name) {
    ElMessage.warning('请输入名称')
    return
  }
  try {
    const token = localStorage.getItem('token')
    const data = {
      project_id: 1,
      name: form.name,
      description: form.description,
      is_enabled: form.is_enabled
    }
    if (editingId.value) {
      await axios.put(`/api/test-projects/${editingId.value}`, data, {
        headers: { Authorization: `Bearer ${token}` }
      })
      ElMessage.success('已更新')
    } else {
      await axios.post('/api/test-projects/', data, {
        headers: { Authorization: `Bearer ${token}` }
      })
      ElMessage.success('已创建')
    }
    dialogVisible.value = false
    loadProjects()
  } catch (e: any) {
    ElMessage.error(`失败: ${e.message}`)
  }
}

const handleToggle = async (row: TestProject) => {
  try {
    const token = localStorage.getItem('token')
    await axios.put(`/api/test-projects/${row.id}`, {
      ...row,
      is_enabled: !row.is_enabled
    }, {
      headers: { Authorization: `Bearer ${token}` }
    })
    ElMessage.success(row.is_enabled ? '已禁用' : '已启用')
    loadProjects()
  } catch (e: any) {
    ElMessage.error(`失败: ${e.message}`)
  }
}

const handleDelete = async (id: number) => {
  try {
    const token = localStorage.getItem('token')
    await axios.delete(`/api/test-projects/${id}`, {
      headers: { Authorization: `Bearer ${token}` }
    })
    ElMessage.success('已删除')
    loadProjects()
  } catch (e: any) {
    ElMessage.error(`失败: ${e.message}`)
  }
}

onMounted(() => {
  loadProjects()
})
</script>

<style scoped>
.test-projects {
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

.header-actions {
  display: flex;
  gap: 12px;
}
</style>
