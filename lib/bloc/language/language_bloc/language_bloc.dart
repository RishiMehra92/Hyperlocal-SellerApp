import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../config/hive_storage.dart';
import '../../../model/language_model/language_model.dart';
import '../../../service/language_repo.dart';
import '../language_list_bloc/language_list_bloc.dart';

part 'language_event.dart';
part 'language_state.dart';

class LanguageBloc extends Bloc<LanguageEvent, LanguageState> {
  final LanguageRepo languageRepo;
  LanguageListBloc? languageListBloc;

  LanguageBloc({LanguageRepo? languageRepo, this.languageListBloc})
      : languageRepo = languageRepo ?? LanguageRepo(),
        super(_resolveInitialState(languageRepo ?? LanguageRepo())) {
    on<LoadLanguage>(_onLoadLanguage);
    on<FetchLanguages>(_onFetchLanguages);
    on<ChangeLanguage>(_onChangeLanguage);
  }

  static LanguageState _resolveInitialState(LanguageRepo repo) {
    final activeCode = HiveStorage.languageCode;
    final cached = LanguageRepo.getCachedLanguagesSync();
    final matchingLang = cached?.data?.languages?.firstWhere(
      (l) => l.code == activeCode,
      orElse: () => LanguageData(code: activeCode, direction: 'ltr'),
    );
    final isRtl = matchingLang?.direction?.toLowerCase() == 'rtl';

    return LanguageLoaded(
      languageModel: cached ?? LanguageModel(),
      defaultLanguage: cached?.data?.defaultLanguage ?? 'en',
      currentLanguage: activeCode,
      locale: Locale(activeCode),
      isRtl: isRtl,
    );
  }

  Future<void> _onLoadLanguage(
      LoadLanguage event, Emitter<LanguageState> emit) async {
    final savedLang = HiveStorage.languageCode;

    final cached = LanguageRepo.getCachedLanguagesSync() ?? await languageRepo.getCachedLanguages();
    if (cached != null && cached.data != null) {
      final activeCode =
          (savedLang.isNotEmpty) ? savedLang : (cached.data?.defaultLanguage ?? 'en');
      final matchingLang = cached.data?.languages?.firstWhere(
        (l) => l.code == activeCode,
        orElse: () => LanguageData(code: activeCode, direction: 'ltr'),
      );
      final isRtl = matchingLang?.direction?.toLowerCase() == 'rtl';

      emit(LanguageLoaded(
        languageModel: cached,
        defaultLanguage: cached.data!.defaultLanguage ?? 'en',
        currentLanguage: activeCode,
        locale: Locale(activeCode),
        isRtl: isRtl,
      ));
    } else if (state is! LanguageLoaded) {
      emit(LanguageLoading());
    }

    try {
      final data = await languageRepo.fetchLanguages();
      if (data.success == true && data.data != null) {
        final activeCode =
            (savedLang.isNotEmpty) ? savedLang : (data.data?.defaultLanguage ?? 'en');
        final matchingLang = data.data?.languages?.firstWhere(
          (l) => l.code == activeCode,
          orElse: () => LanguageData(code: activeCode, direction: 'ltr'),
        );
        final isRtl = matchingLang?.direction?.toLowerCase() == 'rtl';

        emit(LanguageLoaded(
          languageModel: data,
          defaultLanguage: data.data!.defaultLanguage ?? 'en',
          currentLanguage: activeCode,
          locale: Locale(activeCode),
          isRtl: isRtl,
        ));
      } else if (state is! LanguageLoaded) {
        emit(LanguageError(message: data.message ?? 'Failed to load languages'));
      }
    } catch (e) {
      if (state is! LanguageLoaded) {
        emit(LanguageError(message: e.toString()));
      }
    }
  }

  Future<void> _onFetchLanguages(
      FetchLanguages event, Emitter<LanguageState> emit) async {
    add(const LoadLanguage());
  }

  Future<void> _onChangeLanguage(
      ChangeLanguage event, Emitter<LanguageState> emit) async {
    try {
      await HiveStorage.setLanguageCode(event.languageCode);
      LanguageRepo.loadActiveLabelsSync(event.languageCode);

      languageListBloc?.add(FetchLanguageList(locale: event.languageCode));

      final currentModel =
          state is LanguageLoaded ? (state as LanguageLoaded).languageModel : null;

      if (currentModel != null) {
        final matchingLang = currentModel.data?.languages?.firstWhere(
          (l) => l.code == event.languageCode,
          orElse: () => LanguageData(code: event.languageCode, direction: 'ltr'),
        );
        final isRtl = matchingLang?.direction?.toLowerCase() == 'rtl';

        emit(LanguageLoaded(
          languageModel: currentModel,
          defaultLanguage: currentModel.data?.defaultLanguage ?? 'en',
          currentLanguage: event.languageCode,
          locale: Locale(event.languageCode),
          isRtl: isRtl,
        ));
      } else {
        add(const LoadLanguage());
      }
    } catch (e) {
      emit(LanguageError(message: e.toString()));
    }
  }
}
