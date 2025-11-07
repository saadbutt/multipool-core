// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MaxHeap.sol";
import "./MinHeap.sol";

contract EvmSort {
    uint256 constant BITS_PER_SLOT = 256;

    using MaxHeap for MaxHeap.Data;
    using MinHeap for MinHeap.Data;

    mapping(uint256 => uint256) public firstLayerMax;
    mapping(uint256 => uint256) public secondLayerMax;
    MaxHeap.Data private thirdLayerHeapMax;

    mapping(uint256 => uint256) public firstLayerMin;
    mapping(uint256 => uint256) public secondLayerMin;
    MinHeap.Data private thirdLayerHeapMin;

    event MaxValuePopped(uint256 value);
    event MinValuePopped(uint256 value);
    event Debug(string message, uint256 value);

    constructor() {}

    function setValue(uint256 element, bool exists, bool isMax) public {
        uint256 elementIndex = element;
        uint256 firstLayerIndex = elementIndex / BITS_PER_SLOT;
        uint256 firstLayerBit = elementIndex % BITS_PER_SLOT;

        uint256 secondLayerIndex = firstLayerIndex / BITS_PER_SLOT;
        uint256 secondLayerBit = firstLayerIndex % BITS_PER_SLOT;

        if (isMax) {
            if (exists) {
                firstLayerMax[firstLayerIndex] |= (1 << firstLayerBit);
                secondLayerMax[secondLayerIndex] |= (1 << secondLayerBit);
                if (thirdLayerHeapMax.indices[uint32(secondLayerIndex)] == 0) {
                    thirdLayerHeapMax.insert(uint32(secondLayerIndex));
                }
            } else {
                firstLayerMax[firstLayerIndex] &= ~(1 << firstLayerBit);
                if (firstLayerMax[firstLayerIndex] == 0) {
                    secondLayerMax[secondLayerIndex] &= ~(1 << secondLayerBit);
                    if (secondLayerMax[secondLayerIndex] == 0) {
                        thirdLayerHeapMax.popMax();
                    }
                }
            }
        } else {
            if (exists) {
                firstLayerMin[firstLayerIndex] |= (1 << firstLayerBit);
                secondLayerMin[secondLayerIndex] |= (1 << secondLayerBit);
                if (thirdLayerHeapMin.indices[uint32(secondLayerIndex)] == 0) {
                    thirdLayerHeapMin.insert(uint32(secondLayerIndex));
                }
            } else {
                firstLayerMin[firstLayerIndex] &= ~(1 << firstLayerBit);
                if (firstLayerMin[firstLayerIndex] == 0) {
                    secondLayerMin[secondLayerIndex] &= ~(1 << secondLayerBit);
                    if (secondLayerMin[secondLayerIndex] == 0) {
                        thirdLayerHeapMin.popMin();
                    }
                }
            }
        }
    }

    function hasElement(uint256 element, bool isMax) public view returns (bool) {
        uint256 elementIndex = element;
        uint256 firstLayerIndex = elementIndex / BITS_PER_SLOT;
        uint256 firstLayerBit = elementIndex % BITS_PER_SLOT;

        if (isMax) {
            return (firstLayerMax[firstLayerIndex] & (1 << firstLayerBit)) != 0;
        } else {
            return (firstLayerMin[firstLayerIndex] & (1 << firstLayerBit)) != 0;
        }
    }

    function getMax() public view returns (uint256) {
        if (thirdLayerHeapMax.packedHeap.length == 0) {
            return 0;
        }

        uint32 bestSecondLayerIndex = thirdLayerHeapMax._getValue(0);
        uint256 secondLayerIndex = uint256(bestSecondLayerIndex);
        uint256 secondLayerValue = secondLayerMax[secondLayerIndex];
        if (secondLayerValue == 0) {
            return 0;
        }
        uint256 highestBitInSecondLayer = findHighestSetBit(secondLayerValue);
        uint256 firstLayerIndex = secondLayerIndex * BITS_PER_SLOT + highestBitInSecondLayer;
        uint256 bitfield = firstLayerMax[firstLayerIndex];

        if (bitfield == 0) {
            return 0;
        }

        uint256 firstBitSet = findHighestSetBit(bitfield);
        uint256 maxElement = firstLayerIndex * BITS_PER_SLOT + firstBitSet;

        return maxElement;
    }

    function getMin() public view returns (uint256) {
        if (thirdLayerHeapMin.packedHeap.length == 0) {
            return 0;
        }

        uint32 bestSecondLayerIndex = thirdLayerHeapMin._getValue(0);
        uint256 secondLayerIndex = uint256(bestSecondLayerIndex);
        uint256 secondLayerValue = secondLayerMin[secondLayerIndex];

        if (secondLayerValue == 0) {
            return 0;
        }
        uint256 lowestBitInSecondLayer = findLowestSetBit(secondLayerValue);
        uint256 firstLayerIndex = secondLayerIndex * BITS_PER_SLOT + lowestBitInSecondLayer;
        uint256 bitfield = firstLayerMin[firstLayerIndex];

        if (bitfield == 0) {
            return 0;
        }

        uint256 firstBitSet = findLowestSetBit(bitfield);
        uint256 minElement = firstLayerIndex * BITS_PER_SLOT + firstBitSet;

        return minElement;
    }

    function removeSpecificMax(uint256 element) public returns (uint256) {
        uint256 elementIndex = element;
        uint256 firstLayerIndex = elementIndex / BITS_PER_SLOT;
        uint256 firstLayerBit = elementIndex % BITS_PER_SLOT;

        uint256 secondLayerIndex = firstLayerIndex / BITS_PER_SLOT;
        uint256 secondLayerBit = firstLayerIndex % BITS_PER_SLOT;

        uint256 secondLayerValue = secondLayerMax[secondLayerIndex];
        require((secondLayerValue & (1 << secondLayerBit)) != 0, "Element not found");

        thirdLayerHeapMax.popSpecific(uint32(secondLayerIndex));

        firstLayerMax[firstLayerIndex] &= ~(1 << firstLayerBit);
        if (firstLayerMax[firstLayerIndex] == 0) {
            secondLayerMax[secondLayerIndex] &= ~(1 << secondLayerBit);
        }

        emit Debug("removeSpecificMax", element);
        return element;
    }

    function removeSpecificMin(uint256 element) public returns (uint256) {
        uint256 elementIndex = element;
        uint256 firstLayerIndex = elementIndex / BITS_PER_SLOT;
        uint256 firstLayerBit = elementIndex % BITS_PER_SLOT;

        uint256 secondLayerIndex = firstLayerIndex / BITS_PER_SLOT;
        uint256 secondLayerBit = firstLayerIndex % BITS_PER_SLOT;

        uint256 secondLayerValue = secondLayerMin[secondLayerIndex];
        require((secondLayerValue & (1 << secondLayerBit)) != 0, "Element not found");

        thirdLayerHeapMin.popSpecificValue(uint32(secondLayerIndex));

        firstLayerMin[firstLayerIndex] &= ~(1 << firstLayerBit);
        if (firstLayerMin[firstLayerIndex] == 0) {
            secondLayerMin[secondLayerIndex] &= ~(1 << secondLayerBit);
        }

        emit Debug("removeSpecificMin", element);
        return element;
    }

    function popMax() public returns (uint256) {
        require(thirdLayerHeapMax.packedHeap.length > 0, "No elements available");
        uint32 bestSecondLayerIndex = thirdLayerHeapMax._getValue(0);
        uint256 secondLayerIndex = uint256(bestSecondLayerIndex);
        uint256 secondLayerValue = secondLayerMax[secondLayerIndex];
        uint256 highestBitInSecondLayer = findHighestSetBit(secondLayerValue);
        uint256 firstLayerIndex = secondLayerIndex * BITS_PER_SLOT + highestBitInSecondLayer;
        uint256 bitfield = firstLayerMax[firstLayerIndex];
        require(bitfield != 0, "No elements available after pop");
        uint256 firstBitSet = findHighestSetBit(bitfield);
        uint256 maxElement = firstLayerIndex * BITS_PER_SLOT + firstBitSet;

        firstLayerMax[firstLayerIndex] &= ~(1 << firstBitSet);
        if (firstLayerMax[firstLayerIndex] == 0) {
            secondLayerValue &= ~(1 << highestBitInSecondLayer);
            secondLayerMax[secondLayerIndex] = secondLayerValue;
            if (secondLayerValue == 0) {
                thirdLayerHeapMax.popMax();
            }
        }

        emit MaxValuePopped(maxElement);
        emit Debug("popMax", maxElement);
        return maxElement;
    }

    function popMin() public returns (uint256) {
        require(thirdLayerHeapMin.packedHeap.length > 0, "No elements available");
        uint32 bestSecondLayerIndex = thirdLayerHeapMin._getValue(0);
        uint256 secondLayerIndex = uint256(bestSecondLayerIndex);
        uint256 secondLayerValue = secondLayerMin[secondLayerIndex];
        uint256 lowestBitInSecondLayer = findLowestSetBit(secondLayerValue);
        uint256 firstLayerIndex = secondLayerIndex * BITS_PER_SLOT + lowestBitInSecondLayer;
        uint256 bitfield = firstLayerMin[firstLayerIndex];
        require(bitfield != 0, "No elements available after pop");
        uint256 firstBitSet = findLowestSetBit(bitfield);
        uint256 minElement = firstLayerIndex * BITS_PER_SLOT + firstBitSet;

        firstLayerMin[firstLayerIndex] &= ~(1 << firstBitSet);
        if (firstLayerMin[firstLayerIndex] == 0) {
            secondLayerValue &= ~(1 << lowestBitInSecondLayer);
            secondLayerMin[secondLayerIndex] = secondLayerValue;
            if (secondLayerValue == 0) {
                thirdLayerHeapMin.popMin();
            }
        }

        emit MinValuePopped(minElement);
        emit Debug("popMin", minElement);
        return minElement;
    }

    function findHighestSetBit(uint256 bitfield) internal pure returns (uint256) {
        require(bitfield > 0, "Bitfield cannot be zero");
        uint256 index;
        assembly {
            let temp := bitfield
            if gt(temp, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) {
                temp := shr(128, temp)
                index := add(index, 128)
            }
            if gt(temp, 0xFFFFFFFFFFFFFFFF) {
                temp := shr(64, temp)
                index := add(index, 64)
            }
            if gt(temp, 0xFFFFFFFF) {
                temp := shr(32, temp)
                index := add(index, 32)
            }
            if gt(temp, 0xFFFF) {
                temp := shr(16, temp)
                index := add(index, 16)
            }
            if gt(temp, 0xFF) {
                temp := shr(8, temp)
                index := add(index, 8)
            }
            if gt(temp, 0xF) {
                temp := shr(4, temp)
                index := add(index, 4)
            }
            if gt(temp, 0x3) {
                temp := shr(2, temp)
                index := add(index, 2)
            }
            if gt(temp, 0x1) {
                index := add(index, 1)
            }
        }
        return index;
    }

    function findLowestSetBit(uint256 bitfield) internal pure returns (uint256) {
        require(bitfield > 0, "Bitfield cannot be zero");
        uint256 index;
        assembly {
            let temp := bitfield
            index := 0
            if iszero(and(temp, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) {
                temp := shr(128, temp)
                index := add(index, 128)
            }
            if iszero(and(temp, 0xFFFFFFFFFFFFFFFF)) {
                temp := shr(64, temp)
                index := add(index, 64)
            }
            if iszero(and(temp, 0xFFFFFFFF)) {
                temp := shr(32, temp)
                index := add(index, 32)
            }
            if iszero(and(temp, 0xFFFF)) {
                temp := shr(16, temp)
                index := add(index, 16)
            }
            if iszero(and(temp, 0xFF)) {
                temp := shr(8, temp)
                index := add(index, 8)
            }
            if iszero(and(temp, 0xF)) {
                temp := shr(4, temp)
                index := add(index, 4)
            }
            if iszero(and(temp, 0x3)) {
                temp := shr(2, temp)
                index := add(index, 2)
            }
            if iszero(and(temp, 0x1)) {
                index := add(index, 1)
            }
        }
        return index;
    }
}
