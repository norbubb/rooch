
<a name="0x3_builtin_validators"></a>

# Module `0x3::builtin_validators`



-  [Constants](#@Constants_0)
-  [Function `genesis_init`](#0x3_builtin_validators_genesis_init)
-  [Function `is_builtin_auth_validator`](#0x3_builtin_validators_is_builtin_auth_validator)


<pre><code><b>use</b> <a href="">0x2::context</a>;
<b>use</b> <a href="auth_validator_registry.md#0x3_auth_validator_registry">0x3::auth_validator_registry</a>;
<b>use</b> <a href="ethereum_validator.md#0x3_ethereum_validator">0x3::ethereum_validator</a>;
<b>use</b> <a href="native_validator.md#0x3_native_validator">0x3::native_validator</a>;
</code></pre>



<a name="@Constants_0"></a>

## Constants


<a name="0x3_builtin_validators_ErrorGenesisInit"></a>



<pre><code><b>const</b> <a href="builtin_validators.md#0x3_builtin_validators_ErrorGenesisInit">ErrorGenesisInit</a>: u64 = 1;
</code></pre>



<a name="0x3_builtin_validators_genesis_init"></a>

## Function `genesis_init`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="builtin_validators.md#0x3_builtin_validators_genesis_init">genesis_init</a>(ctx: &<b>mut</b> <a href="_Context">context::Context</a>, _genesis_account: &<a href="">signer</a>)
</code></pre>



<a name="0x3_builtin_validators_is_builtin_auth_validator"></a>

## Function `is_builtin_auth_validator`



<pre><code><b>public</b> <b>fun</b> <a href="builtin_validators.md#0x3_builtin_validators_is_builtin_auth_validator">is_builtin_auth_validator</a>(auth_validator_id: u64): bool
</code></pre>
