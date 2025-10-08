/*
import 'package:big_bazzar_admin/constants/app_colors.dart';
import 'package:big_bazzar_admin/constants/app_strings.dart';
import 'package:big_bazzar_admin/constants/const_assets.dart';
import 'package:big_bazzar_admin/router/routes.dart';
import 'package:big_bazzar_admin/screens/dashboard/customers_list_screen.dart';
import 'package:big_bazzar_admin/screens/dashboard/dashboard_screen.dart';
import 'package:big_bazzar_admin/screens/dashboard/messasges_list_screen.dart';
import 'package:big_bazzar_admin/screens/dashboard/orders_list_screen.dart';
import 'package:big_bazzar_admin/screens/dashboard/products_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SideMenu extends StatefulWidget {

  final bool hideMenu;

  const SideMenu({super.key, required this.hideMenu});

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {

  List<Widget> pageList = [];

  int currentIndex = 0;

  // List<Map> menuList = ['Dashboard', 'Orders', 'Products', 'Customers', 'Messages', 'Settings'];
  // List<Map> menuList = [
  //   {'icons': Icons.home,
  //   'title': MenuListStrings.dashboard},
  //   {'icons': Icons.feed_outlined,
  //   'title': MenuListStrings.orders},
  //   {'icons': Icons.shopping_bag,
  //   'title': MenuListStrings.products},
  //   {'icons': Icons.person_pin,
  //   'title': MenuListStrings.customers},
  //   {'icons': Icons.point_of_sale,
  //   'title': MenuListStrings.pos},
  //   {'icons': Icons.message,
  //   'title': MenuListStrings.messages},
  //   {'icons': Icons.category,
  //   'title': MenuListStrings.category},
  //   {'icons': Icons.settings,
  //   'title': MenuListStrings.settings},
  // ];


  List<SideMenuItem> menuList = [
    SideMenuItem(icons: Icons.home, title: MenuListStrings.dashboard, showSubMenu: false, subMenuItemList: []),
    SideMenuItem(icons: Icons.feed_outlined, title: MenuListStrings.orders, showSubMenu: false, subMenuItemList: []),
    SideMenuItem(icons: Icons.shopping_bag, title: MenuListStrings.products, showSubMenu: false, subMenuItemList: [
      SubMenuItem(title: MenuListStrings.productList),
      SubMenuItem(title: MenuListStrings.categoryList),
    ]),
    SideMenuItem(icons: Icons.person_pin, title: MenuListStrings.customers, showSubMenu: false, subMenuItemList: []),
    SideMenuItem(icons: Icons.point_of_sale, title: MenuListStrings.pos, showSubMenu: false, subMenuItemList: []),
    SideMenuItem(icons: Icons.message, title: MenuListStrings.messages, showSubMenu: false, subMenuItemList: []),
    SideMenuItem(icons: Icons.settings, title: MenuListStrings.settings, showSubMenu: false, subMenuItemList: []),
  ];

  @override
  void initState() {

    pageList = <Widget>[
      const DashboardScreen(),
      const OrdersListScreen(),
      const ProductListScreen(),
      const CustomersListScreen(),
      const MessagesListScreen(),
      Container(),
    ];

    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.whiteColor,
      width: widget.hideMenu ? 250 : 0,
      height: MediaQuery.of(context).size.height,
      child: Padding(
        padding: const EdgeInsets.only(left: 20.0,right: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const SizedBox(
              height: 20,
            ),

            SizedBox(
              height: 50,
              child: Image.asset(ImageAssets.logo),
            ),
            // Text.rich(
            //   TextSpan(
            //     children: [
            //       const TextSpan(text: 'Big', style: TextStyle(color: AppColors.colorAccentSwatch, fontSize: 25, fontWeight: FontWeight.w800)),
            //       TextSpan(text: 'Bazzar', style: TextStyle(color: AppColors.greenPrimaryColor, fontSize: 25, fontWeight: FontWeight.w800)),
            //     ]
            //   ),
            // ),

            const SizedBox(
              height: 35,
            ),

            Center(
                child: ListView.builder(
                  itemCount: menuList.length,
                  padding: EdgeInsets.zero,
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    return Column(
                      children: [
                        InkWell(
                          onTap: (){

                            setState(() {
                              SelectIndex.selectedIndex = index;
                            });


                            if(menuList[index].title == MenuListStrings.dashboard){
                              Get.toNamed(Routes.dashBoard);
                            }else if(menuList[index].title == MenuListStrings.orders){
                              Get.toNamed(Routes.ordersList);
                            }else if(menuList[index].title == MenuListStrings.products){
                              // Get.toNamed(Routes.productList);
                              setState(() {
                                menuList[index].showSubMenu = !menuList[index].showSubMenu;
                              });
                              // Get.toNamed(Routes.productList);
                            }else if(menuList[index].title == MenuListStrings.customers){
                              Get.toNamed(Routes.costumerList);
                            }else if(menuList[index].title == MenuListStrings.messages){
                              Get.toNamed(Routes.messageList);
                            }else if(menuList[index].title == MenuListStrings.pos){
                              Get.toNamed(Routes.posScreen);
                            }else if(menuList[index].title == MenuListStrings.category){
                              Get.toNamed(Routes.categoryListScreen);
                            }else if(menuList[index].title == MenuListStrings.settings){
                              Get.toNamed(Routes.settingScreen);
                            }else{
                              // Get.toNamed(Routes.s);
                            }

                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: SelectIndex.selectedIndex == index ? AppColors.colorAccentSwatch : Colors.transparent,
                              borderRadius: BorderRadius.all(Radius.circular(5))
                            ),

                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
                              child: Row(
                                children: [
                                  SizedBox(height: 25, width: 25,
                                  child: Icon(menuList[index].icons, color: SelectIndex.selectedIndex == index ? AppColors.whiteColor :AppColors.grayColor),
                                  ),
                                  const SizedBox(
                                    width: 15,
                                  ),
                                  Text(menuList[index].title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: SelectIndex.selectedIndex == index ? AppColors.whiteColor :AppColors.grayColor)),
                                ],
                              ),
                            ),
                          ),
                        ),

                        if(menuList[index].showSubMenu)
                        Align(
                          alignment: Alignment.centerRight,
                          child: ListView.builder(
                          itemCount: menuList[index].subMenuItemList.length,
                          padding: EdgeInsets.zero,
                          physics: NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemBuilder: (context, subIndex) {
                          return InkWell(
                            onTap: (){
                              if(menuList[index].subMenuItemList[subIndex].title == MenuListStrings.productList){
                                Get.toNamed(Routes.productList);
                              }else if(menuList[index].subMenuItemList[subIndex].title == MenuListStrings.categoryList){
                                Get.toNamed(Routes.categoryListScreen);
                              }else{
                                // Get.toNamed(Routes.s);
                              }
                            },
                            child: SizedBox(
                              height: 40,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 30, right: 10.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Icon(Icons.circle, color: AppColors.grayColor, size: 8,),
                                    SizedBox(width: 8),
                                    Text( menuList[index].subMenuItemList[subIndex].title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.grayColor)),
                                  ],
                                ),
                              ),
                            ),
                          );}),
                        )
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}



class SideMenuItem {
  SideMenuItem(
      {required this.icons, required this.title, required this.showSubMenu, required this.subMenuItemList});
  final IconData icons;
  final String title;
  bool showSubMenu;
  List<SubMenuItem> subMenuItemList;
}
class SubMenuItem {
  SubMenuItem(
      {required this.title});
  final String title;
}*/
