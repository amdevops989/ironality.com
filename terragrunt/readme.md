               +--------------------+
               |    EKS Control     |
               |      Plane         |
               | (Manages cluster)  |
               +---------+----------+
                         |
                         | Creates pods, secrets
                         |
          +--------------v---------------+
          |          Pods / Apps         |
          |  (Requests PVCs via StorageClass) 
          +---------------+-------------+
                          |
                          | PersistentVolumeClaim
                          |
                +---------v----------+
                |   EBS CSI Driver   |
                |   (kube-system)    |
                +---------+----------+
                          |
                          | Uses IRSA role → KMS CMK
                          | Create encrypted volume
                +---------v----------+
                |     KMS Key        |
                |  (Customer CMK)    |
                +---------+----------+
                          ^
                          | Encrypt / Decrypt / CreateGrant
                          |
          +---------------+----------------+
          |  EC2 Node (Karpenter Spot / NG) |
          | Root volume encrypted via KMS   |
          | IAM Node Role has KMS access    |
          +---------------+----------------+
                          |
                          | Attaches PVC volumes
                          | (encrypted via KMS)
                          |
          +---------------v----------------+
          |   EBS Volumes (app data)       |
          |   Encrypted with same CMK      |
          +--------------------------------+
