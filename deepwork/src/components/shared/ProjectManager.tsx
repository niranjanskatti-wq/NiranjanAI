import { Plus, Trash2 } from 'lucide-react'
import { useState } from 'react'
import { db, uid } from '@/db'
import { useProjects } from '@/hooks/data'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { confirmDialog } from '@/components/ui/confirm'
import { toast } from '@/components/ui/toast'
import { ACCENT_PRESETS } from '@/lib/settings'

/** Create, rename, recolor and delete project tags. */
export function ProjectManager() {
  const projects = useProjects()
  const [name, setName] = useState('')
  const [color, setColor] = useState(ACCENT_PRESETS[1])

  const add = async () => {
    const n = name.trim()
    if (!n) return
    await db.projects.put({ id: uid(), name: n, color, order: (projects?.length ?? 0) + 1 })
    setName('')
    setColor(ACCENT_PRESETS[((projects?.length ?? 0) + 2) % ACCENT_PRESETS.length])
  }

  const remove = async (id: string, pname: string) => {
    const count = await db.tasks.where('project_id').equals(id).count()
    const ok = await confirmDialog({
      title: `Delete “${pname}”?`,
      description: count ? `${count} task(s) will keep existing without a project.` : 'This project has no tasks.',
      confirmLabel: 'Delete',
      danger: true,
    })
    if (!ok) return
    await db.transaction('rw', db.projects, db.tasks, async () => {
      await db.projects.delete(id)
      await db.tasks.where('project_id').equals(id).modify({ project_id: null })
    })
    toast('Project deleted')
  }

  return (
    <div className="space-y-2">
      {(projects ?? []).map((p) => (
        <div key={p.id} className="flex items-center gap-2">
          <label className="relative size-9 shrink-0 cursor-pointer overflow-hidden rounded-full border border-border" style={{ background: p.color }} title="Change color">
            <input
              type="color"
              value={p.color}
              onChange={(e) => void db.projects.update(p.id, { color: e.target.value })}
              className="absolute inset-0 size-full cursor-pointer opacity-0"
              aria-label={`Color for ${p.name}`}
            />
          </label>
          <Input defaultValue={p.name} onBlur={(e) => e.target.value.trim() && e.target.value !== p.name && void db.projects.update(p.id, { name: e.target.value.trim() })} aria-label="Project name" />
          <Button variant="ghost" size="icon" onClick={() => void remove(p.id, p.name)} aria-label={`Delete ${p.name}`}>
            <Trash2 />
          </Button>
        </div>
      ))}
      {projects?.length === 0 && <p className="py-2 text-sm text-muted">No projects yet.</p>}
      <form
        className="flex items-center gap-2 pt-2"
        onSubmit={(e) => {
          e.preventDefault()
          void add()
        }}
      >
        <label className="relative size-9 shrink-0 cursor-pointer overflow-hidden rounded-full border border-border" style={{ background: color }}>
          <input type="color" value={color} onChange={(e) => setColor(e.target.value)} className="absolute inset-0 size-full cursor-pointer opacity-0" aria-label="New project color" />
        </label>
        <Input value={name} onChange={(e) => setName(e.target.value)} placeholder="New project" />
        <Button type="submit" variant="secondary" size="icon" disabled={!name.trim()} aria-label="Add project">
          <Plus />
        </Button>
      </form>
      <div className="flex flex-wrap gap-1.5 pt-1">
        {ACCENT_PRESETS.map((c) => (
          <button key={c} onClick={() => setColor(c)} className="size-5 rounded-full ring-offset-2 ring-offset-card transition-transform hover:scale-110" style={{ background: c, boxShadow: c === color ? `0 0 0 2px ${c}` : undefined }} aria-label={`Use ${c}`} />
        ))}
      </div>
    </div>
  )
}
