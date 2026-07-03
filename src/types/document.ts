export interface DocumentItem {
  id: string;
  name: string;
  type: string; // pdf, txt, xlsx, js, etc.
  size: string;
  folder: string;
  tags: string[];
  pinned: boolean;
  recent: boolean;
  content: string;
  updatedAt: string;
}
