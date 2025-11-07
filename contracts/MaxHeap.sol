// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library MaxHeap {
    struct Data {
        uint256[] packedHeap;  // Each uint256 can store 8 uint32 values.
        mapping(uint32 => uint32) indices;  // Mapping from value to its index in the heap.
    }

    uint256 constant MAX_UINT32 = 2**32 - 1;  // Maximum value for uint32.
    uint256 constant VALUES_PER_SLOT = 8;  // Number of uint32 values that can be stored in a uint256.

    /**
     * @dev Inserts a new value into the heap.
     * @param self The heap data structure.
     * @param value The value to be inserted.
     */
    function insert(Data storage self, uint32 value) public {
        // Calculate the index where the new value will be inserted.
        uint32 packedIndex = uint32(self.packedHeap.length * VALUES_PER_SLOT + self.packedHeap.length % VALUES_PER_SLOT);
        // Store the index of the new value.
        self.indices[value] = packedIndex;
        // Set the value at the calculated index.
        _setValue(self, packedIndex, value);
        // Restore the heap property by moving the new value up.
        heapifyUp(self, packedIndex);
    }

    /**
     * @dev Removes and returns the maximum value from the heap.
     * @param self The heap data structure.
     * @return The maximum value from the heap.
     */
    function popMax(Data storage self) public returns (uint32) {
        require(self.packedHeap.length > 0, "Heap is empty");

        // The maximum value is at the root of the heap.
        uint32 maxIndex = 0;
        uint32 maxValue = _getValue(self, maxIndex);

        // The last value in the heap.
        uint32 lastIndex = uint32(self.packedHeap.length * VALUES_PER_SLOT - 1);
        uint32 lastValue = _getValue(self, lastIndex);
        // Remove the last value from the heap.
        _removeLastValue(self);

        if (lastIndex > 0) {
            // Replace the root with the last value.
            _setValue(self, maxIndex, lastValue);
            // Update the index of the last value.
            self.indices[lastValue] = maxIndex;
            // Restore the heap property by moving the new root down.
            heapifyDown(self, maxIndex);
        }

        // Remove the index of the maximum value.
        delete self.indices[maxValue];
        return maxValue;
    }


    /**
     * @dev Pops a specific value from the heap.
     * @param self The heap data structure.
     * @param value The value to pop.
    */
    function popSpecific(Data storage self, uint32 value) public {
        uint32 index = self.indices[value];
        require(index != MAX_UINT32, "Value not found");

        uint32 lastIndex = uint32(self.packedHeap.length * VALUES_PER_SLOT - 1);
        if (index != lastIndex) {
            uint32 lastValue = _getValue(self, lastIndex);
            _setValue(self, index, lastValue);
            self.indices[lastValue] = index;
        }

        _removeLastValue(self);
        delete self.indices[value];

        // Restore heap property by heapifying down from the index where the specific value was located.
        heapifyDown(self, index);
    }

    /**
     * @dev Retrieves the value at a specific index in the heap.
     * @param self The heap data structure.
     * @param index The index to retrieve the value from.
     * @return The value at the specified index.
     */
    function _getValue(Data storage self, uint32 index) internal view returns (uint32) {
        uint256 slot = index / VALUES_PER_SLOT;  // Determine which slot the index falls into.
        uint256 offset = index % VALUES_PER_SLOT;  // Determine the offset within the slot.
        // Extract the value from the slot.
        return uint32((self.packedHeap[slot] >> (offset * 32)) & MAX_UINT32);
    }

    /**
     * @dev Sets the value at a specific index in the heap.
     * @param self The heap data structure.
     * @param index The index to set the value at.
     * @param value The value to set at the specified index.
     */
    function _setValue(Data storage self, uint32 index, uint32 value) internal {
        uint256 slot = index / VALUES_PER_SLOT;  // Determine which slot the index falls into.
        uint256 offset = index % VALUES_PER_SLOT;  // Determine the offset within the slot.
        uint256 shift = offset * 32;  // Calculate the bit shift needed for the offset.
        uint256 mask = ~(MAX_UINT32 << shift);  // Create a mask to clear the specific bits.

        if (slot == self.packedHeap.length) {
            // If the slot does not exist, push a new slot.
            self.packedHeap.push(0);
        }

        // Set the value in the slot, clearing and then setting the specific bits.
        self.packedHeap[slot] = (self.packedHeap[slot] & mask) | (uint256(value) << shift);
    }

    /**
     * @dev Removes the last value from the heap.
     * @param self The heap data structure.
     */
    function _removeLastValue(Data storage self) internal {
        uint256 lastSlot = self.packedHeap.length - 1;  // Get the last slot.
        uint256 offset = self.packedHeap.length % VALUES_PER_SLOT;  // Determine the offset within the slot.
        if (offset == 0) {
            // If offset is 0, the slot is empty, so pop it.
            self.packedHeap.pop();
        } else {
            uint256 shift = (offset - 1) * 32;  // Calculate the bit shift needed for the offset.
            uint256 mask = ~(MAX_UINT32 << shift);  // Create a mask to clear the specific bits.
            // Clear the last value in the slot.
            self.packedHeap[lastSlot] &= mask;
        }
    }

    /**
     * @dev Reorders the heap upwards from a specific index to maintain the max heap property.
     * @param self The heap data structure.
     * @param index The index to reorder from.
     */
    function heapifyUp(Data storage self, uint32 index) internal {
        uint32 value = _getValue(self, index);  // Get the value at the index.
        while (index > 0) {
            uint32 parentIndex = (index - 1) / 2;  // Calculate the parent index.
            uint32 parentValue = _getValue(self, parentIndex);  // Get the value of the parent.
            if (value <= parentValue) {
                // If the value is less than or equal to the parent's value, the heap property is satisfied.
                break;
            }
            // Move the parent value down.
            _setValue(self, index, parentValue);
            self.indices[parentValue] = index;
            index = parentIndex;  // Move up to the parent's index.
        }
        // Set the value at the new index.
        _setValue(self, index, value);
        self.indices[value] = index;
    }

    /**
     * @dev Reorders the heap downwards from a specific index to maintain the max heap property.
     * @param self The heap data structure.
     * @param index The index to reorder from.
     */
    function heapifyDown(Data storage self, uint32 index) internal {
        uint32 length = uint32(self.packedHeap.length * VALUES_PER_SLOT);  // Get the total length of the heap.
        uint32 value = _getValue(self, index);  // Get the value at the index.

        while (true) {
            uint32 leftChild = 2 * index + 1;  // Calculate the left child's index.
            uint32 rightChild = 2 * index + 2;  // Calculate the right child's index.
            uint32 largestChild = index;  // Assume the largest child is the current index.

            if (leftChild < length && _getValue(self, leftChild) > _getValue(self, largestChild)) {
                // If the left child's value is greater than the current largest value, update the largest child.
                largestChild = leftChild;
            }

            if (rightChild < length && _getValue(self, rightChild) > _getValue(self, largestChild)) {
                // If the right child's value is greater than the current largest value, update the largest child.
                largestChild = rightChild;
            }

            if (largestChild == index) {
                // If the largest child is still the current index, the heap property is satisfied.
                break;
            }

            // Move the largest child's value up.
            _setValue(self, index, _getValue(self, largestChild));
            self.indices[_getValue(self, largestChild)] = index;
            index = largestChild;  // Move down to the largest child's index.
        }

        // Set the value at the new index.
        _setValue(self, index, value);
        self.indices[value] = index;
    }
}
