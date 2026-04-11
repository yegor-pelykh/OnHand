import { BookmarkJson } from '../models/bookmark.model';
import { GroupJson } from '../models/group.model';
import { GroupStorageJson } from '../models/group-storage';

export function isBookmarkJson(obj: unknown): obj is BookmarkJson {
  if (typeof obj !== 'object' || obj === null) {
    return false;
  }
  if (typeof (obj as { u?: unknown }).u !== 'string' || typeof (obj as { t?: unknown }).t !== 'string') {
    return false;
  }
  if ((obj as { i?: unknown }).i !== undefined && typeof (obj as { i?: unknown }).i !== 'string') {
    return false;
  }
  return true;
}

export function isGroupJson(obj: unknown): obj is GroupJson {
  if (typeof obj !== 'object' || obj === null) {
    return false;
  }
  if (typeof (obj as { t?: unknown }).t !== 'string') {
    return false;
  }
  if (!Array.isArray((obj as { b?: unknown[] }).b)) {
    return false;
  }
  for (const bookmark of (obj as { b: unknown[] }).b) {
    if (!isBookmarkJson(bookmark)) {
      return false;
    }
  }
  return true;
}

export function isGroupStorageJson(obj: unknown): obj is GroupStorageJson {
  if (typeof obj !== 'object' || obj === null) {
    return false;
  }
  if (!Array.isArray((obj as { g?: unknown }).g)) {
    return false;
  }
  for (const group of (obj as { g: unknown[] }).g) {
    if (!isGroupJson(group)) {
      return false;
    }
  }
  return true;
}
