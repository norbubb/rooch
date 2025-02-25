// Copyright (c) RoochNetwork
// SPDX-License-Identifier: Apache-2.0

import { ErrCallbackType } from 'src/context/types'
import { AccountDataType } from 'src/context/types'

export type AddAccountBySecretKeyParams = {
  key: string
  rememberMe?: boolean
}

export enum WalletType {
  Metamask = 'Metamask',
  Bitcoin = 'Bitcoin',
}

export type SupportWalletType = {
  enable: boolean
  name: WalletType
}

export type AuthValuesType = {
  loading: boolean
  logout: () => void
  setLoading: (value: boolean) => void
  supportWallets: SupportWalletType[]
  accounts: Map<string, AccountDataType> | null
  defaultAccount: AccountDataType | null
  loginByWallet: (walletType: WalletType, errorCallback?: ErrCallbackType) => void
  loginByNewAccount: (errorCallback?: ErrCallbackType) => void
  loginBySecretKey: (params: AddAccountBySecretKeyParams, errorCallback?: ErrCallbackType) => void
}
