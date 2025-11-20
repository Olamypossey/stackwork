```markdown
# Stackwork - Decentralized Job Marketplace

A smart contract built on the Stacks blockchain (STX) that enables a trustless, decentralized job marketplace with escrow payments and user ratings.

## Overview

Stackwork allows employers to post jobs with escrow funding, freelancers to apply and submit work, and provides automated payment release with user rating capabilities.

## Features

**Job Posting** - Employers create jobs with budget and deadline, funds held in escrow  
**Freelancer Applications** - Apply to open jobs with duplicate prevention  
**Secure Hiring** - Employers select freelancers; only hired freelancers can submit work  
**Work Submission** - Freelancers submit work links for review  
**Escrow & Payment Release** - Funds automatically released upon employer approval  
**User Ratings** - Rate users on a 1-5 star scale with average calculation  

## Contract Functions

### Public Functions

| Function | Description | Parameters |
|----------|-------------|-----------|
| `create-job` | Post a new job with escrow | `title`, `description`, `budget`, `duration` |
| `apply-job` | Apply to an open job | `job-id` |
| `hire` | Select a freelancer for the job | `job-id`, `freelancer` |
| `submit-work` | Submit completed work | `job-id`, `work-link` |
| `approve-work` | Approve work and release payment | `job-id` |
| `rate-user` | Rate a user (1-5 stars) | `user`, `score` |

### Read-Only Functions

| Function | Returns |
|----------|---------|
| `get-job` | Full job details |
| `get-rating` | User's average rating score |
| `get-status` | Current job status |

## Job Lifecycle

```
1. OPEN → Employer creates job with budget held in escrow
2. HIRED → Employer selects freelancer
3. SUBMITTED → Freelancer submits work
4. COMPLETE → Employer approves & funds released to freelancer
5. CANCELED → (optional) Job canceled, funds returned
```

## Error Codes

| Code | Error | Description |
|------|-------|-------------|
| 100 | ERR_NOT_EMPLOYER | Only job employer can perform this action |
| 101 | ERR_NOT_FREELANCER | Only hired freelancer can perform this action |
| 102 | ERR_ALREADY_APPLIED | Already applied to this job |
| 103 | ERR_NOT_HIRED | Not hired for this job |
| 104 | ERR_INVALID_AMOUNT | Invalid amount or rating score |
| 105 | ERR_ALREADY_SUBMITTED | Work already submitted |
| 106 | ERR_NOT_FOUND | Job not found |
| 107 | ERR_ALREADY_APPROVED | Already approved |
| 108 | ERR_ALREADY_RATED | Already rated this user |

## Data Structures

### Jobs Map
```clarity
{
  job-id → {
    employer: principal,
    title: string,
    description: string,
    budget: uint (microSTX),
    deadline: uint (block height),
    status: "open" | "hired" | "submitted" | "complete" | "canceled",
    hired: optional principal,
    submission: optional string
  }
}
```

### Ratings Map
```clarity
{
  user → {
    count: uint (number of ratings),
    total: uint (sum of all rating scores)
  }
}
```

## Usage Example

```clarity
;; 1. Employer posts a job for 10 STX
(contract-call? .stackwork create-job
  "Build a Website"
  "Create a responsive portfolio website"
  u10000000  ;; 10 STX in microSTX
  u1000      ;; 1000 blocks deadline
)

;; 2. Freelancer applies
(contract-call? .stackwork apply-job u1)

;; 3. Employer hires freelancer
(contract-call? .stackwork hire u1 'SP2FREELANCER...)

;; 4. Freelancer submits work
(contract-call? .stackwork submit-work u1 "https://portfolio.com/work")

;; 5. Employer approves and releases payment
(contract-call? .stackwork approve-work u1)

;; 6. Rate the freelancer
(contract-call? .stackwork rate-user 'SP2FREELANCER... u5)
```

## Security Considerations

**Escrow Protection** - Funds held in contract until approved  
**Role Enforcement** - Only authorized parties can perform actions  
**Duplicate Prevention** - Can't apply twice to same job  
**Status Validation** - Jobs must be in correct state for each action  

## Deployment

Deploy to Stacks testnet:
```bash
clarinet contract publish stackwork
```

## License

MIT - Open source decentralized infrastructure
