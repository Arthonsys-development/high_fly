import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/constant/app_strings.dart';
import '../../../config/constant/const_assets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/routes.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {


  @override
  void initState() {
    navigateAfterDelay();

    super.initState();
  }

  navigateAfterDelay() async {
    Future.delayed(const Duration(milliseconds: 600), () {
      // if(token.isNotEmpty){
      //   if (!mounted) return;
      //   context.go(Routes.bottomBar);
      // }else{
      //   if (!mounted) return;
        context.go(Routes.signIn);
      // }
    });

  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                  115.0, 0.0, 115.0, 0.0),
              child: Center(
                child:Image.asset(
                    ImageAssets.highFlyLogo,
                    width: double.infinity,
                    // fit: BoxFit.,
                ),
              )
          ),
        ],
      ),
    );
  }
}
