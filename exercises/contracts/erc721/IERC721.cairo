# SPDX-License-Identifier: MIT
# OpenZeppelin Contracts for Cairo v0.3.0 (token/erc721/IERC721.cairo)

%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IERC721:
    func balanceOf(owner: felt) -> (balance: Uint256):
    end

    func ownerOf(tokenId: Uint256) -> (owner: felt):
    end

    func safeTransferFrom(
            from_: felt,
            to: felt,
            tokenId: Uint256,
            data_len: felt,
            data: felt*
        ):
    end

    func mint(to: felt):
    end

    func transferFrom(from_: felt, to: felt, tokenId: Uint256):
    end

    func approve(approved: felt, tokenId: Uint256):
    end

    func setApprovalForAll(operator: felt, approved: felt):
    end

    func getApproved(tokenId: Uint256) -> (approved: felt):
    end

    func isApprovedForAll(owner: felt, operator: felt) -> (isApproved: felt):
    end

    func getCounter() -> (counter: Uint256):
    end

    func getOriginalOwner(tokenId: Uint256) -> (originalOwner: felt):
    end

    func setErc20_pay(address: felt):
    end

    func mintBuy():
    end
end
