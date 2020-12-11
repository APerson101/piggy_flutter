import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:flutter/cupertino.dart';

import 'package:piggy_flutter/blocs/accounts/accounts.dart';
import 'package:piggy_flutter/blocs/auth/auth.dart';
import 'package:piggy_flutter/blocs/transaction/transaction.dart';
import 'package:piggy_flutter/blocs/transaction_detail/bloc.dart';
import 'package:piggy_flutter/models/tenant_accounts_result.dart';
import 'package:piggy_flutter/repositories/repositories.dart';

class AccountsBloc extends Bloc<AccountsEvent, AccountsState> {
  AccountsBloc(
      {@required this.accountRepository,
      @required this.authBloc,
      @required this.transactionsBloc,
      @required this.transactionDetailBloc})
      : assert(accountRepository != null),
        assert(authBloc != null),
        assert(transactionsBloc != null),
        assert(transactionDetailBloc != null) {
    authBlocSubscription = authBloc.listen((state) {
      if (state is AuthAuthenticated) {
        add(LoadAccounts());
      }
    });

    transactionBlocSubscription = transactionsBloc.listen((state) {
      if (state is TransactionSaved) {
        add(LoadAccounts());
      }
    });

    transactionDetailBlocSubscription = transactionDetailBloc.listen((state) {
      if (state is TransactionDeleted) {
        add(LoadAccounts());
      }
    });
  }

  final AccountRepository accountRepository;

  final AuthBloc authBloc;
  StreamSubscription authBlocSubscription;

  final TransactionBloc transactionsBloc;
  StreamSubscription transactionBlocSubscription;

  final TransactionDetailBloc transactionDetailBloc;
  StreamSubscription transactionDetailBlocSubscription;

  @override
  AccountsState get initialState => AccountsLoading();

  @override
  Stream<AccountsState> mapEventToState(
    AccountsEvent event,
  ) async* {
    if (event is LoadAccounts) {
      yield* _mapLoadAccountsToState();
    }
  }

  Stream<AccountsState> _mapLoadAccountsToState() async* {
    try {
      final TenantAccountsResult allAccounts =
          await accountRepository.getTenantAccounts();
      yield AccountsLoaded(
          allAccounts.userAccounts, allAccounts.familyAccounts);
    } catch (e) {
      AccountsNotLoaded();
    }
  }

  @override
  Future<void> close() {
    authBlocSubscription.cancel();
    transactionBlocSubscription.cancel();
    transactionDetailBlocSubscription.cancel();
    return super.close();
  }
}
