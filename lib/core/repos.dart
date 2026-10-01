import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/backend/backend.dart';
import '../data/repositories/account_repo.dart';
import '../data/repositories/community_repo.dart';
import '../data/repositories/conferences_repo.dart';
import '../data/repositories/consult_repo.dart';
import '../data/repositories/discovery_repo.dart';
import '../data/repositories/households_repo.dart';
import '../data/repositories/messaging_repo.dart';
import '../data/repositories/relationships_repo.dart';
import '../data/repositories/safety_repo.dart';
import 'providers.dart';

Backend _b(Ref ref) => ref.watch(backendProvider);

final discoveryRepoProvider = Provider<DiscoveryRepository>(
  (ref) => DiscoveryRepository(_b(ref)),
);

final messagingRepoProvider = Provider<MessagingRepository>(
  (ref) => MessagingRepository(_b(ref), ref.watch(signedUrlCacheProvider)),
);

final relationshipsRepoProvider = Provider<RelationshipsRepository>(
  (ref) => RelationshipsRepository(_b(ref)),
);

final householdsRepoProvider = Provider<HouseholdsRepository>(
  (ref) => HouseholdsRepository(_b(ref)),
);

final communityRepoProvider = Provider<CommunityRepository>(
  (ref) => CommunityRepository(_b(ref), ref.watch(signedUrlCacheProvider)),
);

final conferencesRepoProvider = Provider<ConferencesRepository>(
  (ref) => ConferencesRepository(_b(ref)),
);

final safetyRepoProvider = Provider<SafetyRepository>(
  (ref) => SafetyRepository(_b(ref)),
);

final accountRepoProvider = Provider<AccountRepository>(
  (ref) => AccountRepository(_b(ref), ref.watch(signedUrlCacheProvider)),
);

final consultRepoProvider = Provider<ConsultRepository>(
  (ref) => ConsultRepository(_b(ref)),
);
