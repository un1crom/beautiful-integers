/**
 * Seeds — Pre-cached sequence data for offline/demo mode
 *
 * These are the Phase 1 research sequences plus some favorites.
 * When OEIS isn't reachable, the app falls back to these.
 */

export const SEED_DATA = {
  'A000045': {
    number: 45,
    name: 'Fibonacci numbers: F(n) = F(n-1) + F(n-2) with F(0) = 0 and F(1) = 1',
    data: '0,1,1,2,3,5,8,13,21,34,55,89,144,233,377,610,987,1597,2584,4181,6765,10946,17711,28657,46368,75025,121393,196418,317811,514229,832040,1346269,2178309,3524578,5702887,9227465,14930352,24157817,39088169,63245986,102334155,165580141,267914296,433494437,701408733,1134903170,1836311903,2971215073,4807526976,7778742049',
    keyword: 'nonn,core,nice,easy,hear',
    comment: [
      'F(n+2) = number of subsets of {1,2,...,n} that contain no two consecutive elements.',
      'F(n+1) = number of binary sequences of length n that have no two consecutive 1\'s.',
      'The ratio F(n+1)/F(n) converges to the golden ratio (1+sqrt(5))/2 = 1.6180339887...'
    ],
    xref: ['Cf. A000032, A000213, A000931, A001175, A001690, A005478, A039834.'],
    formula: ['F(n) = F(n-1) + F(n-2) with F(0) = 0 and F(1) = 1.', 'F(n) = ((1+sqrt(5))^n - (1-sqrt(5))^n) / (2^n * sqrt(5)).'],
    author: '_N. J. A. Sloane_',
    offset: '0,4'
  },
  'A000040': {
    number: 40,
    name: 'The prime numbers',
    data: '2,3,5,7,11,13,17,19,23,29,31,37,41,43,47,53,59,61,67,71,73,79,83,89,97,101,103,107,109,113,127,131,137,139,149,151,157,163,167,173,179,181,191,193,197,199,211,223,227,229,233,239,241,251,257,263,269,271,277,281,283,293,307,311,313,317,331,337,347,349,353,359,367,373,379,383,389,397,401,409,419,421,431,433,439,443,449,457,461,463,467,479,487,491,499,503,509,521,523,541',
    keyword: 'nonn,core,nice,easy,hear',
    comment: [
      'A natural number is prime if and only if it has exactly 2 divisors.',
      'The prime numbers are the atoms of multiplicative number theory.'
    ],
    xref: ['Cf. A000720, A001223, A002808, A006562, A006880, A008578.'],
    formula: [],
    author: '_N. J. A. Sloane_',
    offset: '1,1'
  },
  'A000041': {
    number: 41,
    name: 'a(n) is the number of partitions of n (the partition numbers)',
    data: '1,1,2,3,5,7,11,15,22,30,42,56,77,101,135,176,231,297,385,490,627,792,1002,1255,1575,1958,2436,3010,3718,4565,5604,6842,8349,10143,12310,14883,17977,21637,26015,31185,37338,44583,53174,63261,75175,89134,105558,124754,147273,173525',
    keyword: 'nonn,core,nice,easy,hear',
    comment: [
      'The partition function p(n) counts the number of ways of writing n as a sum of positive integers without regard to order.',
      'Hardy and Ramanujan showed that p(n) ~ exp(Pi*sqrt(2n/3)) / (4*n*sqrt(3)).'
    ],
    xref: ['Cf. A000009, A000079, A000219, A000726, A002865, A008284.'],
    formula: ['a(n) = (1/n) * Sum_{k=1..n} A000203(k) * a(n-k) for n > 0.'],
    author: '_N. J. A. Sloane_',
    offset: '0,3'
  },
  'A005132': {
    number: 5132,
    name: 'Recaman\'s sequence: a(0) = 0; for n > 0, a(n) = a(n-1) - n if positive and not already in the sequence, otherwise a(n) = a(n-1) + n',
    data: '0,1,3,6,2,7,13,20,12,21,11,22,10,23,9,24,8,25,43,62,42,63,41,18,42,17,43,16,44,15,45,14,46,79,113,78,114,77,39,78,38,79,37,80,36,81,35,82,34,83,33,84,32,85,31,86,30,87,29,88,28,89,27,90,26,91,157,224,156,225,155',
    keyword: 'nonn,nice,hear',
    comment: [
      'This is a self-avoiding sequence: it never repeats a value.',
      'It is not known whether every positive integer eventually appears in this sequence.',
      'The sequence exhibits dramatic jumps and returns, creating a distinctive visual arc pattern.'
    ],
    xref: ['Cf. A008336, A057167, A064227, A064228, A064229, A064230.'],
    formula: [],
    author: '_N. J. A. Sloane_',
    offset: '0,3'
  },
  'A000002': {
    number: 2,
    name: 'Kolakoski sequence: a(n) is length of n-th run; a(1) = 1; sequence consists just of 1\'s and 2\'s',
    data: '1,2,2,1,1,2,1,2,2,1,2,2,1,1,2,1,1,2,2,1,2,1,1,2,1,2,2,1,1,2,1,1,2,1,2,2,1,2,2,1,1,2,1,2,2,1,2,1,1,2,1,1,2,2,1,2,2,1,1,2,1,2,2,1,2,2,1,1,2,1,1,2,1,2,2,1,2,1,1,2,2,1,2,2,1,1,2,1,2,2,1,2,1,1,2,1,1,2,2,1',
    keyword: 'nonn,core,nice,easy',
    comment: [
      'This is a self-describing sequence: the sequence of run lengths is the sequence itself.',
      'It is conjectured that the density of 1\'s is 1/2, but this remains unproved.'
    ],
    xref: ['Cf. A000001, A006928, A042942, A078880, A171899.'],
    formula: [],
    author: '_N. J. A. Sloane_',
    offset: '1,2'
  },
  'A000108': {
    number: 108,
    name: 'Catalan numbers: C(n) = binomial(2n,n)/(n+1) = (2n)!/(n!(n+1)!)',
    data: '1,1,2,5,14,42,132,429,1430,4862,16796,58786,208012,742900,2674440,9694845,35357670,129644790,477638700,1767263190,6564120420,24466267020,91482563640,343059613650,1289904147324,4861946401452',
    keyword: 'nonn,core,nice,easy',
    comment: [
      'C(n) counts the number of expressions containing n pairs of parentheses which are correctly matched.',
      'Also the number of full binary trees with n+1 leaves.'
    ],
    xref: ['Cf. A000245, A001006, A001700, A006318, A014137, A014138.'],
    formula: ['C(n) = binomial(2n,n)/(n+1).', 'C(n) = (2n)!/(n!(n+1)!).'],
    author: '_N. J. A. Sloane_',
    offset: '0,3'
  },
  'A010060': {
    number: 10060,
    name: 'Thue-Morse sequence: let A_k denote the first 2^k terms; then A_0 = 0 and for k >= 0, A_{k+1} = A_k B_k, where B_k is obtained from A_k by interchanging 0\'s and 1\'s',
    data: '0,1,1,0,1,0,0,1,1,0,0,1,0,1,1,0,1,0,0,1,0,1,1,0,0,1,1,0,1,0,0,1,1,0,0,1,0,1,1,0,0,1,1,0,1,0,0,1,0,1,1,0,1,0,0,1,1,0,0,1,0,1,1,0,1,0,0,1,0,1,1,0,0,1,1,0,1,0,0,1,0,1,1,0,1,0,0,1,1,0,0,1,0,1,1,0,0,1,1,0',
    keyword: 'nonn,core,nice,easy',
    comment: [
      'a(n) = number of 1\'s in binary representation of n, mod 2.',
      'This is perhaps the simplest example of a sequence which is 2-automatic but not eventually periodic.'
    ],
    xref: ['Cf. A001969, A000069, A036577, A036580, A106400.'],
    formula: ['a(n) = A000120(n) mod 2.'],
    author: '_N. J. A. Sloane_',
    offset: '0,1'
  },
  'A006577': {
    number: 6577,
    name: 'Number of halving and tripling steps to reach 1 in \'3x+1\' problem (or Collatz problem), or -1 if 1 is never reached',
    data: '0,1,7,2,5,8,16,3,19,6,14,9,9,17,17,4,12,20,20,7,7,15,15,10,23,10,111,18,18,18,106,5,26,13,13,21,21,21,34,8,109,8,29,16,16,16,104,11,24,24',
    keyword: 'nonn,nice,look,hear',
    comment: [
      'The Collatz conjecture states that for any positive integer n, the sequence n, f(n), f(f(n)), ... eventually reaches 1.',
      'This is one of the most famous unsolved problems in mathematics.'
    ],
    xref: ['Cf. A006370, A033491, A006667, A005186.'],
    formula: [],
    author: '_N. J. A. Sloane_',
    offset: '1,3'
  }
};

/**
 * Get seed sequence data as a parsed OEIS-like object
 */
export function getSeedSequence(id) {
  const raw = SEED_DATA[id];
  if (!raw) return null;
  return raw;
}

/**
 * Get all seed IDs
 */
export function getSeedIds() {
  return Object.keys(SEED_DATA);
}
