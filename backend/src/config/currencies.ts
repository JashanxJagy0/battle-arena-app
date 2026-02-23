export interface CurrencyNetwork {
  network: string;
  addressRegex: RegExp;
  minDeposit: number;
  minWithdrawal: number;
  estimatedFee: number;
}

export interface SupportedCurrency {
  currency: string;
  name: string;
  coingeckoId: string;
  networks: CurrencyNetwork[];
}

export const SUPPORTED_CURRENCIES: SupportedCurrency[] = [
  {
    currency: 'BTC',
    name: 'Bitcoin',
    coingeckoId: 'bitcoin',
    networks: [
      {
        network: 'bitcoin',
        addressRegex: /^(bc1|[13])[a-zA-HJ-NP-Z0-9]{25,62}$/,
        minDeposit: 5,
        minWithdrawal: 5,
        estimatedFee: 2,
      },
    ],
  },
  {
    currency: 'ETH',
    name: 'Ethereum',
    coingeckoId: 'ethereum',
    networks: [
      {
        network: 'eth',
        addressRegex: /^0x[a-fA-F0-9]{40}$/,
        minDeposit: 5,
        minWithdrawal: 5,
        estimatedFee: 1,
      },
    ],
  },
  {
    currency: 'USDT',
    name: 'Tether USD',
    coingeckoId: 'tether',
    networks: [
      {
        network: 'eth',
        addressRegex: /^0x[a-fA-F0-9]{40}$/,
        minDeposit: 1,
        minWithdrawal: 5,
        estimatedFee: 1,
      },
      {
        network: 'tron',
        addressRegex: /^T[a-zA-Z0-9]{33}$/,
        minDeposit: 1,
        minWithdrawal: 5,
        estimatedFee: 1,
      },
      {
        network: 'bsc',
        addressRegex: /^0x[a-fA-F0-9]{40}$/,
        minDeposit: 1,
        minWithdrawal: 5,
        estimatedFee: 0.5,
      },
    ],
  },
  {
    currency: 'USDC',
    name: 'USD Coin',
    coingeckoId: 'usd-coin',
    networks: [
      {
        network: 'eth',
        addressRegex: /^0x[a-fA-F0-9]{40}$/,
        minDeposit: 1,
        minWithdrawal: 5,
        estimatedFee: 1,
      },
      {
        network: 'bsc',
        addressRegex: /^0x[a-fA-F0-9]{40}$/,
        minDeposit: 1,
        minWithdrawal: 5,
        estimatedFee: 0.5,
      },
    ],
  },
  {
    currency: 'LTC',
    name: 'Litecoin',
    coingeckoId: 'litecoin',
    networks: [
      {
        network: 'litecoin',
        addressRegex: /^[LM3][a-km-zA-HJ-NP-Z1-9]{26,33}$/,
        minDeposit: 5,
        minWithdrawal: 5,
        estimatedFee: 0.5,
      },
    ],
  },
  {
    currency: 'BNB',
    name: 'BNB',
    coingeckoId: 'binancecoin',
    networks: [
      {
        network: 'bsc',
        addressRegex: /^0x[a-fA-F0-9]{40}$/,
        minDeposit: 5,
        minWithdrawal: 5,
        estimatedFee: 0.5,
      },
    ],
  },
];
