import { Group } from './group';
import { Notifier } from './notifier';

const keyGroups = 'g';

export class GroupStorage extends Notifier {
  private _groups: Group[];

  public get groupsLength(): number {
    return this._groups.length;
  }

  public get isEmpty(): boolean {
    return this.groupsLength === 0;
  }

  public get isNotEmpty(): boolean {
    return this.groupsLength > 0;
  }

  public get titles(): string[] {
    return this._groups.map((g) => g.title);
  }

  public get json(): string {
    const json = {
      [keyGroups]: this._groups.map((g) => g.json),
    };
    return JSON.stringify(json);
  }

  constructor() {
    super();
    this._groups = [];
  }

  private handleGroupChange(): void {
    this.emit();
  }

  public groupAt(index: number): Group | undefined {
    return 0 <= index && index < this._groups.length
      ? this._groups[index]
      : undefined;
  }

  public groupIndexWhere(
    predicate: (value: Group, index: number, obj: Group[]) => unknown,
  ): number {
    return this._groups.findIndex(predicate);
  }

  public groupFirstWhere(
    predicate: (value: Group, index: number, obj: Group[]) => unknown,
  ): Group | undefined {
    return this._groups.find(predicate);
  }

  public groupsMap<T>(
    callbackfn: (value: Group, index: number, array: Group[]) => T,
  ): T[] {
    return this._groups.map(callbackfn);
  }

  public addGroup(group: Group): Group {
    this._groups.push(group);
    group.addListener(() => this.handleGroupChange());
    this.emit();
    return group;
  }

  public moveGroup(oldIndex: number, newIndex: number): void {
    const group = this._groups[oldIndex];
    this._groups.splice(oldIndex, 1);
    this._groups.splice(newIndex, 0, group);
    this.emit();
  }

  public removeGroup(group: Group): void {
    group.removeListener(this.handleGroupChange);
    const index = this._groups.indexOf(group);
    if (index >= 0) {
      this._groups.splice(index, 1);
    }
    this.emit();
  }

  public replaceAll(groups: Group[]): void {
    if (!GroupStorage._groupsEqual(this._groups, groups)) {
      for (const g of this._groups) {
        g.removeListener(this.handleGroupChange);
      }
      this._groups = groups;
      for (const g of this._groups) {
        g.addListener(() => this.handleGroupChange());
      }
      this.emit();
    }
  }

  public replaceByDefault(): void {
    this.replaceAll([
      // TODO: use translatable title
      new Group(this, 'New group', []),
    ]);
  }

  public replaceFromJson(jsonString: string | undefined): void {
    if (jsonString != null) {
      const json = JSON.parse(jsonString);
      this.replaceAll(
        (json[keyGroups] as []).map((j) => Group.fromJson(this, j)),
      );
    } else {
      this.replaceAll([]);
    }
  }

  public replaceFrom(storage: GroupStorage): void {
    this.replaceAll(storage._groups);
  }

  public indexOf(group: Group): number {
    return this._groups.indexOf(group);
  }

  public clone(): GroupStorage {
    const storage = new GroupStorage();
    storage.replaceAll(this._groups.map((g) => g.clone(storage)));
    return storage;
  }

  private static _groupsEqual(l1: Group[], l2: Group[]): boolean {
    if (l1.length != l2.length) {
      return false;
    }
    for (var i = 0; i < l1.length; i++) {
      if (!Group.equals(l1[i], l2[i])) {
        return false;
      }
    }
    return true;
  }
}
