"use client";

import React, { useState } from "react";
import { useWorkspace } from "@/context/WorkspaceContext";
import {
  Upload,
  FolderOpen,
  Star,
  Clock,
  FileText,
  Search,
  Building,
  Plane,
  Sprout
} from "lucide-react";
import { Card } from "@/components/ui/Card";
import { Button } from "@/components/ui/Button";
import { Modal } from "@/components/ui/Modal";
import { DocumentItem } from "@/types/document";

export function DocumentsView() {
  const { documents, addDocument } = useWorkspace();
  const [search, setSearch] = useState("");
  const [activeFolder, setActiveFolder] = useState<string>("all");
  const [activeTag, setActiveTag] = useState<string>("all");
  const [selectedDoc, setSelectedDoc] = useState<DocumentItem | null>(null);

  // Upload Form State
  const [showUploadModal, setShowUploadModal] = useState(false);
  const [uploadName, setUploadName] = useState("");
  const [uploadFolder, setUploadFolder] = useState("General");
  const [uploadTags, setUploadTags] = useState("");
  const [uploadContent, setUploadContent] = useState("");

  const folders = ["all", "IFZA Setup", "Travel", "AgriTech", "General"] as const;
  const allTags = Array.from(new Set(documents.flatMap((d) => d.tags)));

  const filteredDocs = documents.filter((d) => {
    const matchesSearch = d.name.toLowerCase().includes(search.toLowerCase()) || 
                          d.content.toLowerCase().includes(search.toLowerCase());
    const matchesFolder = activeFolder === "all" || d.folder === activeFolder;
    const matchesTag = activeTag === "all" || d.tags.includes(activeTag);
    return matchesSearch && matchesFolder && matchesTag;
  });

  const handleUploadSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!uploadName.trim()) return;
    
    const tagsArray = uploadTags
      .split(",")
      .map((t) => t.trim())
      .filter((t) => t.length > 0);
      
    addDocument(
      uploadName,
      uploadName.split(".").pop() || "txt",
      "1.2 MB",
      uploadFolder,
      tagsArray,
      uploadContent || "Empty draft document."
    );

    // Reset upload fields
    setUploadName("");
    setUploadFolder("General");
    setUploadTags("");
    setUploadContent("");
    setShowUploadModal(false);
  };

  return (
    <div className="flex-1 flex h-full overflow-hidden">
      {/* Sidebar: Directories */}
      <div className="w-56 bg-neutral-950/20 border-r border-white/5 flex flex-col shrink-0 h-full p-4 space-y-6">
        <div>
          <span className="text-[10px] font-semibold text-neutral-500 uppercase tracking-widest px-2 block mb-2 select-none">
            Knowledge Folders
          </span>
          <div className="space-y-1">
            {folders.map((f) => {
              const isActive = activeFolder === f;
              return (
                <button
                  key={f}
                  onClick={() => setActiveFolder(f)}
                  className={`w-full flex items-center gap-2 px-2.5 py-1.5 rounded-md text-xs font-medium text-left transition-colors cursor-pointer focus-visible:ring-1 focus-visible:ring-indigo-500/50 outline-none ${
                    isActive
                      ? "bg-indigo-600/20 text-indigo-300 border-l-2 border-indigo-500"
                      : "text-neutral-400 hover:text-white hover:bg-white/5"
                  }`}
                >
                  <FolderOpen className="w-3.5 h-3.5" />
                  <span className="capitalize">{f === "all" ? "All Folders" : f}</span>
                </button>
              );
            })}
          </div>
        </div>

        <div>
          <span className="text-[10px] font-semibold text-neutral-500 uppercase tracking-widest px-2 block mb-2 select-none">
            Tag Library
          </span>
          <div className="flex flex-wrap gap-1.5 px-2">
            <button
              onClick={() => setActiveTag("all")}
              className={`px-2 py-0.5 rounded text-[9px] font-semibold tracking-wide border cursor-pointer transition-all ${
                activeTag === "all"
                  ? "bg-indigo-600/20 text-indigo-300 border-indigo-500/30"
                  : "bg-white/5 text-neutral-400 border-white/5 hover:text-white"
              }`}
            >
              All Tags
            </button>
            {allTags.map((tag) => {
              const isActive = activeTag === tag;
              return (
                <button
                  key={tag}
                  onClick={() => setActiveTag(tag)}
                  className={`px-2 py-0.5 rounded text-[9px] font-semibold tracking-wide border cursor-pointer transition-all ${
                    isActive
                      ? "bg-indigo-600/20 text-indigo-300 border-indigo-500/30"
                      : "bg-white/5 text-neutral-400 border-white/5 hover:text-white"
                  }`}
                >
                  #{tag}
                </button>
              );
            })}
          </div>
        </div>
      </div>

      {/* Main Panel: Documents display */}
      <div className="flex-1 flex flex-col h-full bg-neutral-950/10 p-6 space-y-6 overflow-y-auto">
        {/* Controls header */}
        <div className="flex justify-between items-center border-b border-white/5 pb-4 shrink-0">
          <div>
            <h1 className="text-xl font-bold text-white">Document Repository</h1>
            <p className="text-xs text-neutral-400 mt-1">Manage static knowledge bases, scraped lists, and system templates.</p>
          </div>
          <Button
            variant="primary"
            size="sm"
            onClick={() => setShowUploadModal(true)}
            className="flex items-center gap-1.5 animate-pulse-slow"
          >
            <Upload className="w-3.5 h-3.5" />
            <span>Upload File</span>
          </Button>
        </div>

        {/* Search bar */}
        <div className="relative max-w-md group">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-neutral-500 group-focus-within:text-indigo-400" />
          <input
            type="text"
            placeholder="Search documents by name or contents..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full bg-white/5 border border-white/10 rounded-lg pl-9 pr-4 py-1.5 text-xs text-neutral-200 focus:outline-none focus:border-indigo-500/50 focus:ring-1 focus:ring-indigo-500/50"
          />
        </div>

        {/* List Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {filteredDocs.length === 0 ? (
            <div className="col-span-full py-16 text-center text-neutral-500 font-mono text-xs">
              No index files matched your query filters.
            </div>
          ) : (
            filteredDocs.map((doc) => {
              let FolderIcon = FileText;
              if (doc.folder === "IFZA Setup") FolderIcon = Building;
              else if (doc.folder === "Travel") FolderIcon = Plane;
              else if (doc.folder === "AgriTech") FolderIcon = Sprout;

              return (
                <Card
                  key={doc.id}
                  onClick={() => setSelectedDoc(doc)}
                  className="p-4 cursor-pointer hover:scale-[1.01] flex flex-col justify-between h-40 text-left"
                >
                  <div className="flex justify-between items-start">
                    <div className="p-2 rounded-lg bg-neutral-900 border border-white/5 text-neutral-400">
                      <FolderIcon className="w-4 h-4 text-indigo-400" />
                    </div>
                    {doc.pinned && (
                      <Star className="w-3.5 h-3.5 fill-indigo-500 text-indigo-400" />
                    )}
                  </div>

                  <div className="mt-3">
                    <h3 className="text-xs font-bold text-neutral-200 truncate">{doc.name}</h3>
                    <p className="text-[10px] text-neutral-500 mt-1 line-clamp-2 leading-relaxed font-mono">
                      {doc.content}
                    </p>
                  </div>

                  <div className="flex items-center justify-between border-t border-white/5 pt-2.5 mt-2.5 text-[9px] text-neutral-500">
                    <span className="font-mono">{doc.size}</span>
                    <span className="flex items-center gap-0.5">
                      <Clock className="w-2.5 h-2.5" />
                      {doc.updatedAt}
                    </span>
                  </div>
                </Card>
              );
            })
          )}
        </div>
      </div>

      {/* Document View Modal */}
      <Modal
        isOpen={selectedDoc !== null}
        onClose={() => setSelectedDoc(null)}
        title={selectedDoc ? selectedDoc.name : ""}
      >
        {selectedDoc && (
          <div className="space-y-4">
            <div className="flex justify-between items-center text-[10px] text-neutral-400 bg-white/5 border border-white/5 rounded-lg p-2.5 font-mono">
              <div>Folder: <span className="text-neutral-200">{selectedDoc.folder}</span></div>
              <div>Size: <span className="text-neutral-200">{selectedDoc.size}</span></div>
              <div>Updated: <span className="text-neutral-200">{selectedDoc.updatedAt}</span></div>
            </div>

            <div className="rounded-lg border border-white/10 bg-black/90 p-4 font-mono text-xs text-neutral-300 max-h-72 overflow-y-auto whitespace-pre-wrap leading-relaxed shadow-inner">
              {selectedDoc.content}
            </div>

            <div className="flex flex-wrap gap-1">
              {selectedDoc.tags.map((tag) => (
                <span key={tag} className="px-2 py-0.5 rounded-full text-[9px] bg-indigo-500/10 text-indigo-400 border border-indigo-500/10">
                  #{tag}
                </span>
              ))}
            </div>

            <div className="flex justify-end">
              <Button variant="secondary" onClick={() => setSelectedDoc(null)}>
                Done
              </Button>
            </div>
          </div>
        )}
      </Modal>

      {/* Upload Document Modal */}
      <Modal
        isOpen={showUploadModal}
        onClose={() => setShowUploadModal(false)}
        title="Upload / Register Document"
      >
        <form onSubmit={handleUploadSubmit} className="space-y-4 text-xs">
          <div className="space-y-1">
            <label className="block text-neutral-400 font-semibold">Document Name</label>
            <input
              type="text"
              required
              value={uploadName}
              onChange={(e) => setUploadName(e.target.value)}
              placeholder="e.g. IFZA_Regulatory_Filing.txt"
              className="w-full bg-white/5 border border-white/10 rounded-lg p-2.5 text-neutral-200 focus:outline-none focus:border-indigo-500/50"
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-1">
              <label className="block text-neutral-400 font-semibold">Destination Folder</label>
              <select
                value={uploadFolder}
                onChange={(e) => setUploadFolder(e.target.value)}
                className="w-full bg-neutral-900 border border-white/10 rounded-lg p-2.5 text-neutral-300 focus:outline-none focus:border-indigo-500/50"
              >
                <option value="IFZA Setup">IFZA Setup</option>
                <option value="Travel">Travel</option>
                <option value="AgriTech">AgriTech</option>
                <option value="General">General</option>
              </select>
            </div>
            
            <div className="space-y-1">
              <label className="block text-neutral-400 font-semibold">Tags (comma separated)</label>
              <input
                type="text"
                value={uploadTags}
                onChange={(e) => setUploadTags(e.target.value)}
                placeholder="e.g. legal, visa, audit"
                className="w-full bg-white/5 border border-white/10 rounded-lg p-2.5 text-neutral-200 focus:outline-none focus:border-indigo-500/50"
              />
            </div>
          </div>

          <div className="space-y-1">
            <label className="block text-neutral-400 font-semibold">Document Content / Text Draft</label>
            <textarea
              required
              value={uploadContent}
              onChange={(e) => setUploadContent(e.target.value)}
              placeholder="Enter document text content..."
              className="w-full bg-white/5 border border-white/10 rounded-lg p-2.5 text-neutral-200 focus:outline-none focus:border-indigo-500/50 h-32 resize-none"
            />
          </div>

          <div className="flex justify-end gap-2.5 pt-2 border-t border-white/5">
            <Button variant="secondary" type="button" onClick={() => setShowUploadModal(false)}>
              Cancel
            </Button>
            <Button variant="primary" type="submit">
              Register Index
            </Button>
          </div>
        </form>
      </Modal>
    </div>
  );
}
