import sys

file_path = '/home/salhashemi2/trading-bot-flake/ethereum_executor.py'
with open(file_path, 'r') as f:
    lines = f.readlines()

start_line = -1
end_line = -1

for i, line in enumerate(lines):
    if 'def _approve_token(self, token_address, amount):' in line:
        start_line = i
    if start_line != -1 and 'def get_quote(self, token_in, token_out, amount_in, fee):' in line:
        end_line = i
        break

new_method = """    def _approve_token(self, token_address, amount):
        \"\"\"Approve router to spend tokens. Skips if already approved (cached).
        
        Uses max uint256 for approval to avoid repeated approvals across different amounts.
        Cache persists across runs to minimize RPC calls.
        \"\"\"
        if self.trading_mode != "live" or not self.account:
            return True

        addr_lower = token_address.lower()
        cache_key = f"{addr_lower}:{self.account.address}"

        # Check cached allowance first (max uint256 means fully approved)
        if cache_key in self._allowance_cache:
            cached_allowance = self._allowance_cache[cache_key]
            if cached_allowance == 2**256 - 1:
                logging.info(f"Using cached MAX approval for {token_address}")
                return True
            # If cached but not max, check if it's sufficient for this amount
            if cached_allowance >= amount:
                logging.info(f"Using cached allowance for {token_address}: {cached_allowance}")
                return True

        try:
            token_contract = self.w3.eth.contract(
                address=Web3.to_checksum_address(token_address),
                abi=ERC20_ABI
            )

            # Check current allowance (with retry)
            def _check_allowance():
                return token_contract.functions.allowance(
                    self.account.address,
                    Web3.to_checksum_address(SWAP_ROUTER_ADDRESS)
                ).call()

            allowance = retry_rpc_call(_check_allowance)
            self._allowance_cache[cache_key] = allowance
            logging.info(f"Current allowance for {token_address} on router: {allowance}")

            # If already max approved, cache and return
            if allowance == 2**256 - 1:
                self._allowance_cache[cache_key] = 2**256 - 1
                return True

            # Check if current allowance is sufficient
            if allowance >= amount:
                # Cache this allowance for future checks
                self._allowance_cache[cache_key] = allowance
                return True

            # Capture nonce once to avoid race conditions
            base_nonce = self._get_nonce()

            # Approve max uint256 to avoid future approvals for this token
            # Some tokens (like USDT) require resetting to 0 first if allowance is non-zero
            if allowance > 0:
                logging.info(f"Resetting allowance for {token_address} from {allowance} to 0 before MAX approval")
                tx0 = token_contract.functions.approve(
                    Web3.to_checksum_address(SWAP_ROUTER_ADDRESS),
                    0
                ).build_transaction({
                    'from': self.account.address,
                    'nonce': base_nonce,
                    'gas': 100000,
                    'gasPrice': self._get_gas_price(),
                    'chainId': EXPECTED_CHAIN_ID,
                })
                signed_tx0 = self.w3.eth.account.sign_transaction(tx0, self.private_key)
                
                def _send_reset():
                    try:
                        return self.w3.eth.send_raw_transaction(signed_tx0.raw_transaction)
                    except Exception as e:
                        if "in-flight" in str(e).lower():
                            logging.warning("In-flight transaction limit reached during reset, waiting 10s...")
                            import time
                            time.sleep(10)
                            return self.w3.eth.send_raw_transaction(signed_tx0.raw_transaction)
                        raise

                tx_hash0 = retry_rpc_call(_send_reset)
                retry_rpc_call(lambda: self.w3.eth.wait_for_transaction_receipt(tx_hash0, timeout=120))
                import time
                time.sleep(2) # Extra buffer for delegated accounts
                base_nonce += 1

            # Then approve max with sequential nonce
            logging.info(f"Approving MAX for {token_address} (nonce={base_nonce})")
            tx_max = token_contract.functions.approve(
                Web3.to_checksum_address(SWAP_ROUTER_ADDRESS),
                2**256 - 1
            ).build_transaction({
                'from': self.account.address,
                'nonce': base_nonce,
                'gas': 100000,
                'gasPrice': self._get_gas_price(),
                'chainId': EXPECTED_CHAIN_ID,
            })
            signed_tx_max = self.w3.eth.account.sign_transaction(tx_max, self.private_key)
            
            def _send_max():
                try:
                    return self.w3.eth.send_raw_transaction(signed_tx_max.raw_transaction)
                except Exception as e:
                    if "in-flight" in str(e).lower():
                        logging.warning("In-flight transaction limit reached during MAX approval, waiting 10s...")
                        import time
                        time.sleep(10)
                        return self.w3.eth.send_raw_transaction(signed_tx_max.raw_transaction)
                    raise

            tx_hash_max = retry_rpc_call(_send_max)
            receipt_max = retry_rpc_call(lambda: self.w3.eth.wait_for_transaction_receipt(tx_hash_max, timeout=120))

            if receipt_max.status == 1:
                logging.info(f"Approved MAX for {token_address}. Tx: {tx_hash_max.hex()}")
                self._allowance_cache[cache_key] = 2**256 - 1
                import time
                time.sleep(5)  # Wait for RPC to update nonce
                return tx_hash_max.hex()
            else:
                logging.error(f"Approve MAX transaction failed: {receipt_max}")
                return None
        except Exception as e:
            logging.error(f"Approve failed: {e}")
            return None

"""
new_lines = lines[:start_line] + [new_method] + lines[end_line:]
with open(file_path, 'w') as f:
    f.writelines(new_lines)
print("Successfully fixed _approve_token return values")
