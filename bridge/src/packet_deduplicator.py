from collections import deque
from typing import Set, Tuple

class PacketDeduplicator:
    def __init__(self, capacity: int = 512):
        self.capacity = capacity
        self.seen_set: Set[Tuple[int, int]] = set()
        self.seen_queue: deque = deque()

    def is_duplicate(self, sender_id: int, sequence_id: int) -> bool:
        key = (sender_id, sequence_id)
        if key in self.seen_set:
            return True
        self.seen_set.add(key)
        self.seen_queue.append(key)
        if len(self.seen_queue) > self.capacity:
            old = self.seen_queue.popleft()
            self.seen_set.discard(old)
        return False
