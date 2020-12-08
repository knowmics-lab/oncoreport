import { DockerPullEvent } from './types';

export default class PullStatus {
  idMap: Map<string, number> = new Map<string, number>();

  outputArray: string[] = [];

  pushEvent(event: DockerPullEvent) {
    if (event.id) {
      const { id, status } = event;
      let mappedId;
      if (this.idMap.has(id)) {
        mappedId = this.idMap.get(id);
      } else {
        mappedId = this.outputArray.length;
        this.idMap.set(id, mappedId);
        this.outputArray.push('');
      }
      if (mappedId) {
        const progress = event.progress ? ` ${event.progress}` : '';
        this.outputArray[mappedId] = `${id}: ${status}${progress}`;
      }
    } else {
      this.outputArray.push(event.status);
    }
  }

  isUpToDate() {
    return (
      this.outputArray.filter((s) => s.includes('Image is up to date')).length >
      0
    );
  }

  toString() {
    return this.outputArray.join('\n');
  }
}
