import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:weather/extensions/capitaliza.dart';
import 'package:weather/models/weatherCurrentModel.dart';
import 'package:weather/models/weatherDailyModel.dart';
import 'package:weather/models/weatherHourlyModel.dart';
import 'package:weather/models/weatheralertsModel.dart';
import 'dart:convert';
import '../../models/models.dart';
import '../../models/weatherModel.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage(
      {super.key,
      required this.cityWeather,
      required this.indexx,
      required this.loc,
      this.response});

  final cityWeather;
  final indexx;
  final loc;
  final response;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<ScrollController> _scrollControllers = [];
  ScrollController? _scrollControllerr;
  double _shrinkOffset = 0;
  List<Weather> cityWeather = [];
  List<HourlyData> cityWeatherHr = [];
  List<DailyData> cityWeatherDy = [];
  List<WeatherCurrent> cityWeatherCu = [];
  List<AlertsData> cityWeatherAl = [];
  PageController? _pageController;
  WeatherResponse? _response;
  bool? loca;
  bool _isCollapsed = false;
  bool lastStatus = true;
  double height = 200;
  bool loading = true;
  bool loadingv2 = true;
  int cindex = 0;
  List<PaletteColor> colors = [];
  List<PaletteColor> colors2 = [];

  Future<Object> fetchWeather(lat, lon) async {
    final response = await http.get(Uri.parse(
        'https://api.openweathermap.org/data/3.0/onecall?lat=$lat&lon=$lon&exclude=minutely&appid=e8213ea182adac2d4acd064a0366c189&units=metric'));

    if (response.statusCode == 200) {
      List<HourlyData> weatherData = [];
      List<DailyData> weatherDataa = [];
      List<WeatherCurrent> weatherDataaa = [];
      List<AlertsData> weatherDataaaa = [];
      Map<String, dynamic> json = jsonDecode(response.body);
      List<dynamic> dailyList = json["daily"];
      List<dynamic> hourlyList = json["hourly"];
      List<dynamic> alertsList = json["alerts"] ?? [];
      weatherDataaa.add(WeatherCurrent.fromJson(json));
      for (var alerts in alertsList) {
        print(alertsList);
        weatherDataaaa.add(AlertsData.fromJson(alerts));
      }
      for (var hourly in hourlyList) {
        weatherData.add(HourlyData.fromJson(hourly));
      }
      for (var daily in dailyList) {
        weatherDataa.add(DailyData.fromJson(daily));
      }
      setState(() {
        cityWeatherHr = weatherData;
        cityWeatherDy = weatherDataa;
        cityWeatherCu = weatherDataaa;
        cityWeatherAl = weatherDataaaa;
        loading = false;
      });

      return weatherData;
    } else {
      throw Exception('Failed to load weather data');
    }
  }

  void _scrollListener() {
    if (_isShrink != lastStatus) {
      setState(() {
        lastStatus = _isShrink;
      });
    }
  }

  bool get _isShrink {
    return _scrollControllers[cindex].hasClients &&
        _scrollControllers[cindex].offset > (height - kToolbarHeight);
  }

  @override
  void initState() {
    super.initState();
    cityWeather = widget.cityWeather;
    _pageController = PageController(initialPage: widget.indexx);
    loca = widget.loc;
    cindex = widget.indexx;
    _response = widget.response;
    _scrollControllers = List.generate(
      widget.loc ? cityWeather.length + 1 : cityWeather.length,
      (index) => ScrollController(),
    );
    _scrollControllers[cindex] = ScrollController()
      ..addListener(_scrollListener);
    if (widget.indexx == 0 && widget.loc == true) {
      fetchWeather(_response!.locsInfo.lat.toDouble(),
          _response!.locsInfo.lon.toDouble());
    } else {
      fetchWeather(cityWeather[widget.indexx - 1].citylat.toDouble(),
          cityWeather[widget.indexx - 1].citylon.toDouble());
    }
  }

  @override
  void dispose() {
    _scrollControllers[widget.indexx].removeListener(_scrollListener);
    _scrollControllers[widget.indexx].dispose();
    super.dispose();
  }

  String getTime(final timeStamp) {
    DateTime time = DateTime.fromMillisecondsSinceEpoch(timeStamp * 1000);
    String x = DateFormat.H().format(time);
    return x;
  }

  String getDay(final day) {
    DateTime time = DateTime.fromMillisecondsSinceEpoch(day * 1000);
    String x = DateFormat.E().format(time);
    return x;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: Column(
          children: [
            Flexible(
              child: PageView.builder(
                  onPageChanged: (int) {
                    setState(() {
                      _isShrink;
                      _scrollControllers[widget.indexx]
                          .removeListener(_scrollListener);
                      _scrollControllers[int] = ScrollController()
                        ..addListener(_scrollListener);
                      loading = true;
                      cityWeatherHr = [];
                      cityWeatherDy = [];
                      cityWeatherCu = [];
                      cityWeatherAl = [];
                      cindex = int;
                    });
                    if (int == 0 && widget.loc == true) {
                      setState(() {
                        loading = true;
                      });
                      fetchWeather(_response!.locsInfo.lat.toDouble(),
                          _response!.locsInfo.lon.toDouble());
                    } else if (widget.loc == false) {
                      setState(() {
                        loading = true;
                      });
                      fetchWeather(cityWeather[int].citylat.toDouble(),
                          cityWeather[int].citylon.toDouble());
                    } else {
                      setState(() {
                        loading = true;
                      });
                      fetchWeather(cityWeather[int - 1].citylat.toDouble(),
                          cityWeather[int - 1].citylon.toDouble());
                    }
                  },
                  scrollDirection: Axis.horizontal,
                  itemCount:
                      widget.loc ? cityWeather.length + 1 : cityWeather.length,
                  controller: _pageController,
                  pageSnapping: true,
                  itemBuilder: (ctx, i) {
                    if (i == 0 && widget.loc) {
                      return Container(
                          height: double.infinity,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                                image: AssetImage(
                                    "assets/images/${_response!.weatherInfo.icon}.jpeg"),
                                fit: BoxFit.cover),
                          ),
                          child: NestedScrollView(
                              controller: _scrollControllers[i],
                              headerSliverBuilder:
                                  (context, innerBoxIsScrolled) {
                                return [
                                  SliverAppBar(
                                    elevation: 0,
                                    surfaceTintColor: Colors.transparent,
                                    backgroundColor: Colors.transparent,
                                    pinned: true,
                                    automaticallyImplyLeading: false,
                                    expandedHeight: 235,
                                    flexibleSpace: FlexibleSpaceBar(
                                      collapseMode: CollapseMode.parallax,
                                      background: SafeArea(
                                        child: Column(
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 48),
                                              child: Image(
                                                image: AssetImage(
                                                    'assets/icons/${_response!.weatherInfo.icon}.png'),
                                                fit: BoxFit.none,
                                              ),
                                            ),
                                            Text(
                                              _response!.cityName,
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 25),
                                            ),
                                            Text(
                                              _response!.tempInfo.temperature
                                                      .toStringAsFixed(0) +
                                                  '\u00B0' +
                                                  ' | ' +
                                                  _response!
                                                      .weatherInfo.description
                                                      .toTitleCase(),
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 30,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                            Text(
                                              'H:' +
                                                  _response!
                                                      .tempInfo.temperature
                                                      .toStringAsFixed(0) +
                                                  '\u00B0 ' +
                                                  ' L:' +
                                                  _response!
                                                      .tempInfo.temperature
                                                      .toStringAsFixed(0) +
                                                  '\u00B0',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    centerTitle: true,
                                    title: _isShrink
                                        ? Column(
                                            children: [
                                              Text(
                                                _response!.cityName,
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.w500),
                                              ),
                                              Text(
                                                _response!.tempInfo.temperature
                                                        .toStringAsFixed(0) +
                                                    '\u00B0' +
                                                    ' | ' +
                                                    _response!
                                                        .weatherInfo.description
                                                        .toTitleCase(),
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.w600),
                                              )
                                            ],
                                          )
                                        : null,
                                  ),
                                  SliverOverlapAbsorber(
                                    handle: NestedScrollView
                                        .sliverOverlapAbsorberHandleFor(
                                            context),
                                    sliver: SliverAppBar(
                                      surfaceTintColor: Colors.transparent,
                                      pinned: true,
                                      automaticallyImplyLeading: false,
                                      backgroundColor: Colors.transparent,
                                    ),
                                  ),
                                ];
                              },
                              body: Padding(
                                padding: EdgeInsets.only(top: 77),
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      if (!loading &&
                                          cityWeatherAl.length != 0) ...{
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 22),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: GestureDetector(
                                              onTap: () {
                                                showCupertinoModalPopup<void>(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 0,
                                                          vertical: 0),
                                                      child: Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.black,
                                                          borderRadius:
                                                              BorderRadius.only(
                                                                  topLeft: Radius
                                                                      .circular(
                                                                          16),
                                                                  topRight: Radius
                                                                      .circular(
                                                                          16)),
                                                        ),
                                                        height: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .height -
                                                            500,
                                                        child:
                                                            SingleChildScrollView(
                                                          child:
                                                              Column(children: [
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(8.0),
                                                              child: Container(
                                                                width: double
                                                                    .infinity,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  borderRadius:
                                                                      BorderRadius.all(
                                                                          Radius.circular(
                                                                              9)),
                                                                  color: Color
                                                                      .fromARGB(
                                                                          60,
                                                                          49,
                                                                          49,
                                                                          49),
                                                                ),
                                                              ),
                                                            )
                                                          ]),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                              child: Container(
                                                width: double.infinity,
                                                height: 110,
                                                child: Stack(
                                                  children: [
                                                    BackdropFilter(
                                                      filter: ImageFilter.blur(
                                                          sigmaX: 10,
                                                          sigmaY: 51),
                                                      child: Container(
                                                        height: 110,
                                                        padding:
                                                            EdgeInsets.all(5),
                                                        child: Column(
                                                          children: [
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(8.0),
                                                              child: Row(
                                                                children: [
                                                                  Icon(
                                                                    CupertinoIcons
                                                                        .alarm,
                                                                    size: 18,
                                                                    color: Colors
                                                                        .white54,
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            Divider(
                                                              height: 2,
                                                              color: Colors
                                                                  .white54,
                                                            ),
                                                            Flexible(
                                                              child: Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Padding(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            4.0),
                                                                    child: Text(
                                                                      cityWeatherAl[
                                                                              0]
                                                                          .sender_name,
                                                                      style: TextStyle(
                                                                          overflow: TextOverflow
                                                                              .ellipsis,
                                                                          color: Colors
                                                                              .white54,
                                                                          fontSize:
                                                                              12),
                                                                    ),
                                                                  ),
                                                                  Padding(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            4.0),
                                                                    child: Text(
                                                                      maxLines:
                                                                          1,
                                                                      cityWeatherAl[
                                                                              0]
                                                                          .description,
                                                                      style: TextStyle(
                                                                          overflow: TextOverflow
                                                                              .ellipsis,
                                                                          color: Colors
                                                                              .white70,
                                                                          fontSize:
                                                                              15),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      },
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            top: 5, right: 22, left: 22),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Container(
                                            width: double.infinity,
                                            height: 173,
                                            child: Stack(
                                              children: [
                                                BackdropFilter(
                                                  filter: ImageFilter.blur(
                                                      sigmaX: 10, sigmaY: 51),
                                                  child: Container(
                                                    height: 173,
                                                    padding: EdgeInsets.all(5),
                                                    child: Column(
                                                      children: [
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(8.0),
                                                          child: Row(
                                                            children: [
                                                              Icon(
                                                                CupertinoIcons
                                                                    .clock,
                                                                size: 18,
                                                                color: Colors
                                                                    .white54,
                                                              ),
                                                              Text(
                                                                ' 24-HOURS FORECAST',
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .white54,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        Divider(
                                                          height: 1,
                                                          color: Colors.white54,
                                                        ),
                                                        Flexible(
                                                          child: loading
                                                              ? Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          2.0),
                                                                  child:
                                                                      CupertinoActivityIndicator(),
                                                                )
                                                              : ListView
                                                                  .builder(
                                                                      padding:
                                                                          EdgeInsets
                                                                              .zero,
                                                                      shrinkWrap:
                                                                          true,
                                                                      scrollDirection:
                                                                          Axis
                                                                              .horizontal,
                                                                      itemCount: cityWeatherHr.length >
                                                                              24
                                                                          ? 24
                                                                          : cityWeatherHr
                                                                              .length,
                                                                      itemBuilder:
                                                                          (context,
                                                                              index) {
                                                                        return Container(
                                                                          padding:
                                                                              EdgeInsets.all(22),
                                                                          child:
                                                                              Column(
                                                                            children: [
                                                                              Column(
                                                                                children: [
                                                                                  Text(getTime(cityWeatherHr[index].dt), style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                                                                                ],
                                                                              ),
                                                                              Stack(
                                                                                alignment: AlignmentDirectional.bottomCenter,
                                                                                children: [
                                                                                  Image(
                                                                                    image: AssetImage("assets/icons/${cityWeatherHr[index].weather[0].icon}.png"),
                                                                                    height: 30,
                                                                                    width: 33,
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                              Text(
                                                                                cityWeatherHr[index].temp.toStringAsFixed(0) + '\u00B0',
                                                                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        );
                                                                      }),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 22, vertical: 6),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Container(
                                            height: 415,
                                            child: Stack(
                                              children: [
                                                BackdropFilter(
                                                  filter: ImageFilter.blur(
                                                      sigmaX: 10, sigmaY: 51),
                                                  child: Container(
                                                    height: 415,
                                                    padding: EdgeInsets.all(5),
                                                    child: Column(
                                                      children: [
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  top: 8.0,
                                                                  left: 8.0,
                                                                  right: 8.0,
                                                                  bottom: 8.0),
                                                          child: Row(
                                                            children: [
                                                              Icon(
                                                                CupertinoIcons
                                                                    .calendar,
                                                                size: 18,
                                                                color: Colors
                                                                    .white54,
                                                              ),
                                                              Text(
                                                                ' 8-DAY FORECAST',
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .white54,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        Divider(
                                                          height: 2,
                                                          color: Colors.white54,
                                                        ),
                                                        Flexible(
                                                          child: loading
                                                              ? Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          2.0),
                                                                  child:
                                                                      CupertinoActivityIndicator(),
                                                                )
                                                              : ListView
                                                                  .separated(
                                                                  physics:
                                                                      NeverScrollableScrollPhysics(),
                                                                  scrollDirection:
                                                                      Axis.vertical,
                                                                  shrinkWrap:
                                                                      true,
                                                                  padding:
                                                                      EdgeInsets
                                                                          .zero,
                                                                  itemCount: cityWeatherDy
                                                                              .length >
                                                                          10
                                                                      ? 10
                                                                      : cityWeatherDy
                                                                          .length,
                                                                  itemBuilder:
                                                                      (context,
                                                                          index) {
                                                                    return Column(
                                                                      children: [
                                                                        Container(
                                                                          padding: EdgeInsets.symmetric(
                                                                              horizontal: 8,
                                                                              vertical: 8),
                                                                          child:
                                                                              Row(
                                                                            mainAxisAlignment:
                                                                                MainAxisAlignment.spaceBetween,
                                                                            children: [
                                                                              SizedBox(
                                                                                width: 80,
                                                                                child: Text(
                                                                                  getDay(cityWeatherDy[index].dt),
                                                                                  style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w700),
                                                                                ),
                                                                              ),
                                                                              Stack(
                                                                                alignment: AlignmentDirectional.bottomCenter,
                                                                                children: [
                                                                                  Image(
                                                                                    image: AssetImage("assets/icons/${cityWeatherHr[index].weather[0].icon}.png"),
                                                                                    height: 30,
                                                                                    width: 33,
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                              Text(
                                                                                cityWeatherDy[index].tempmax.toStringAsFixed(0) + '\u00B0 / ' + cityWeatherDy[index].tempmin.toStringAsFixed(0) + '\u00B0',
                                                                                style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w700),
                                                                              )
                                                                            ],
                                                                          ),
                                                                        )
                                                                      ],
                                                                    );
                                                                  },
                                                                  separatorBuilder:
                                                                      (BuildContext
                                                                              context,
                                                                          int index) {
                                                                    return Padding(
                                                                      padding: const EdgeInsets
                                                                          .only(
                                                                          left:
                                                                              8.0,
                                                                          right:
                                                                              8.0),
                                                                      child:
                                                                          Divider(
                                                                        height:
                                                                            0,
                                                                        color: Colors
                                                                            .white54,
                                                                      ),
                                                                    );
                                                                  },
                                                                ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 22, right: 6),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: Container(
                                                  width: double.infinity,
                                                  height: 180,
                                                  child: Stack(
                                                    children: [
                                                      BackdropFilter(
                                                        filter:
                                                            ImageFilter.blur(
                                                                sigmaX: 10,
                                                                sigmaY: 51),
                                                        child: Container(
                                                          height: 180,
                                                          padding:
                                                              EdgeInsets.all(5),
                                                          child: Column(
                                                            children: [
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(
                                                                        8.0),
                                                                child: Row(
                                                                  children: [
                                                                    Icon(
                                                                      CupertinoIcons
                                                                          .wind,
                                                                      size: 18,
                                                                      color: Colors
                                                                          .white54,
                                                                    ),
                                                                    Text(
                                                                      ' WIND',
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                              .white54,
                                                                          fontWeight:
                                                                              FontWeight.w600),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              Flexible(
                                                                child: Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          8.0),
                                                                  child: Stack(
                                                                    children: [
                                                                      Container(
                                                                        width:
                                                                            100, // Đặt kích thước vòng tròn
                                                                        height:
                                                                            100, // Đặt kích thước vòng tròn
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          shape:
                                                                              BoxShape.circle, // Đặt hình dạng hình tròn
                                                                          color:
                                                                              Colors.white10, // Đặt màu xám
                                                                        ),
                                                                        child:
                                                                            Center(
                                                                          child:
                                                                              Column(
                                                                            mainAxisAlignment:
                                                                                MainAxisAlignment.center,
                                                                            children: [
                                                                              Text(
                                                                                _response!.windInfo.windspeed.toStringAsFixed(0),
                                                                                style: TextStyle(
                                                                                  color: Colors.white,
                                                                                  fontSize: 25,
                                                                                  fontWeight: FontWeight.w700,
                                                                                ),
                                                                              ),
                                                                              Text(
                                                                                'km/h',
                                                                                style: TextStyle(
                                                                                  color: Colors.white70,
                                                                                  fontSize: 14,
                                                                                  fontWeight: FontWeight.w700,
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Flexible(
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 6, right: 22),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: Container(
                                                  width: double.infinity,
                                                  height: 180,
                                                  child: Stack(
                                                    children: [
                                                      BackdropFilter(
                                                        filter:
                                                            ImageFilter.blur(
                                                                sigmaX: 10,
                                                                sigmaY: 51),
                                                        child: Container(
                                                          height: 180,
                                                          padding:
                                                              EdgeInsets.all(5),
                                                          child: Column(
                                                            children: [
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(
                                                                        8.0),
                                                                child: Row(
                                                                  children: [
                                                                    Icon(
                                                                      CupertinoIcons
                                                                          .eye_fill,
                                                                      size: 18,
                                                                      color: Colors
                                                                          .white54,
                                                                    ),
                                                                    Text(
                                                                      ' VISIBILITY',
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                              .white54,
                                                                          fontWeight:
                                                                              FontWeight.w600),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              Flexible(
                                                                child: Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          8.0),
                                                                  child: Stack(
                                                                    children: [
                                                                      Container(
                                                                        width:
                                                                            100, // Đặt kích thước vòng tròn
                                                                        height:
                                                                            100, // Đặt kích thước vòng tròn
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          shape:
                                                                              BoxShape.circle, // Đặt hình dạng hình tròn
                                                                          color:
                                                                              Colors.white10, // Đặt màu xám
                                                                        ),
                                                                        child:
                                                                            Center(
                                                                          child:
                                                                              Column(
                                                                            mainAxisAlignment:
                                                                                MainAxisAlignment.center,
                                                                            children: [
                                                                              Text(
                                                                                _response!.visibility.toStringAsFixed(0),
                                                                                style: TextStyle(
                                                                                  color: Colors.white,
                                                                                  fontSize: 25,
                                                                                  fontWeight: FontWeight.w700,
                                                                                ),
                                                                              ),
                                                                              Text(
                                                                                'km',
                                                                                style: TextStyle(
                                                                                  color: Colors.white70,
                                                                                  fontSize: 15,
                                                                                  fontWeight: FontWeight.w700,
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 22, right: 6, top: 5),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: Container(
                                                  width: double.infinity,
                                                  height: 180,
                                                  child: Stack(
                                                    children: [
                                                      BackdropFilter(
                                                        filter:
                                                            ImageFilter.blur(
                                                                sigmaX: 10,
                                                                sigmaY: 51),
                                                        child: Container(
                                                          height: 180,
                                                          padding:
                                                              EdgeInsets.all(5),
                                                          child: Column(
                                                            children: [
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(
                                                                        8.0),
                                                                child: Row(
                                                                  children: [
                                                                    Icon(
                                                                      CupertinoIcons
                                                                          .drop_fill,
                                                                      size: 18,
                                                                      color: Colors
                                                                          .white54,
                                                                    ),
                                                                    Text(
                                                                      ' HUMIDITY',
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                              .white54,
                                                                          fontWeight:
                                                                              FontWeight.w600),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              Flexible(
                                                                child: Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          8.0),
                                                                  child: Stack(
                                                                    children: [
                                                                      Container(
                                                                        width:
                                                                            100, // Đặt kích thước vòng tròn
                                                                        height:
                                                                            100, // Đặt kích thước vòng tròn
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          shape:
                                                                              BoxShape.circle, // Đặt hình dạng hình tròn
                                                                          color:
                                                                              Colors.white10, // Đặt màu xám
                                                                        ),
                                                                        child:
                                                                            Center(
                                                                          child:
                                                                              Column(
                                                                            mainAxisAlignment:
                                                                                MainAxisAlignment.center,
                                                                            children: [
                                                                              Text(
                                                                                '${_response!.tempInfo.humidity.toStringAsFixed(0)}%',
                                                                                style: TextStyle(
                                                                                  color: Colors.white,
                                                                                  fontSize: 25,
                                                                                  fontWeight: FontWeight.w700,
                                                                                ),
                                                                              ),
                                                                              Text(
                                                                                'Humidity',
                                                                                style: TextStyle(
                                                                                  color: Colors.white70,
                                                                                  fontSize: 14,
                                                                                  fontWeight: FontWeight.w700,
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Flexible(
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 6, right: 22, top: 5),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: Container(
                                                  width: double.infinity,
                                                  height: 180,
                                                  child: Stack(
                                                    children: [
                                                      BackdropFilter(
                                                        filter:
                                                            ImageFilter.blur(
                                                                sigmaX: 10,
                                                                sigmaY: 51),
                                                        child: Container(
                                                          height: 180,
                                                          padding:
                                                              EdgeInsets.all(5),
                                                          child: Column(
                                                            children: [
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(
                                                                        8.0),
                                                                child: Row(
                                                                  children: [
                                                                    Icon(
                                                                      CupertinoIcons
                                                                          .sun_max_fill,
                                                                      size: 18,
                                                                      color: Colors
                                                                          .white54,
                                                                    ),
                                                                    Text(
                                                                      ' UV INDEX',
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                              .white54,
                                                                          fontWeight:
                                                                              FontWeight.w600),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              Flexible(
                                                                child: Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          8.0),
                                                                  child: Stack(
                                                                    children: [
                                                                      Container(
                                                                        width:
                                                                            100, // Đặt kích thước vòng tròn
                                                                        height:
                                                                            100, // Đặt kích thước vòng tròn
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          shape:
                                                                              BoxShape.circle, // Đặt hình dạng hình tròn
                                                                          color:
                                                                              Colors.white10, // Đặt màu xám
                                                                        ),
                                                                        child:
                                                                            Center(
                                                                          child:
                                                                              Column(
                                                                            mainAxisAlignment:
                                                                                MainAxisAlignment.center,
                                                                            children: [
                                                                              Text(
                                                                                '${loading ? 0 : cityWeatherCu[0].cityUiv}',
                                                                                style: TextStyle(
                                                                                  color: Colors.white,
                                                                                  fontSize: 25,
                                                                                  fontWeight: FontWeight.w700,
                                                                                ),
                                                                              ),
                                                                              Text(
                                                                                'UV',
                                                                                style: TextStyle(
                                                                                  color: Colors.white70,
                                                                                  fontSize: 14,
                                                                                  fontWeight: FontWeight.w700,
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              )));
                    } else {
                      int cityIndex = widget.loc ? i - 1 : i;
                      return Container(
                          height: double.infinity,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                                image: AssetImage(
                                    "assets/images/${cityWeather[cityIndex].cityIcon}.jpeg"),
                                fit: BoxFit.cover),
                          ),
                          child: NestedScrollView(
                              controller: _scrollControllers[i],
                              headerSliverBuilder:
                                  (context, innerBoxIsScrolled) {
                                return [
                                  SliverAppBar(
                                    elevation: 0,
                                    surfaceTintColor: Colors.transparent,
                                    backgroundColor: Colors.transparent,
                                    pinned: true,
                                    automaticallyImplyLeading: false,
                                    expandedHeight: 235,
                                    flexibleSpace: FlexibleSpaceBar(
                                      collapseMode: CollapseMode.parallax,
                                      background: SafeArea(
                                        child: Column(
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 48),
                                              child: Image(
                                                image: AssetImage(
                                                    'assets/icons/${cityWeather[cityIndex].cityIcon}.png'),
                                                fit: BoxFit.none,
                                              ),
                                            ),
                                            Text(
                                              cityWeather[cityIndex].cityName,
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 25),
                                            ),
                                            Text(
                                              cityWeather[cityIndex]
                                                      .cityTemp
                                                      .toStringAsFixed(0) +
                                                  '\u00B0' +
                                                  ' | ' +
                                                  cityWeather[cityIndex]
                                                      .cityTempDesc
                                                      .toTitleCase(),
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 30,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                            Text(
                                              'H:' +
                                                  cityWeather[cityIndex]
                                                      .cityHtemp
                                                      .toStringAsFixed(0) +
                                                  '\u00B0 ' +
                                                  ' L:' +
                                                  cityWeather[cityIndex]
                                                      .cityLtemp
                                                      .toStringAsFixed(0) +
                                                  '\u00B0',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    centerTitle: true,
                                    title: _isShrink
                                        ? Column(
                                            children: [
                                              Text(
                                                cityWeather[cityIndex].cityName,
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.w500),
                                              ),
                                              Text(
                                                cityWeather[cityIndex]
                                                        .cityTemp
                                                        .toStringAsFixed(0) +
                                                    '\u00B0' +
                                                    ' | ' +
                                                    cityWeather[cityIndex]
                                                        .cityTempDesc
                                                        .toTitleCase(),
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.w600),
                                              )
                                            ],
                                          )
                                        : null,
                                  ),
                                  SliverOverlapAbsorber(
                                    handle: NestedScrollView
                                        .sliverOverlapAbsorberHandleFor(
                                            context),
                                    sliver: SliverAppBar(
                                      surfaceTintColor: Colors.transparent,
                                      pinned: true,
                                      automaticallyImplyLeading: false,
                                      backgroundColor: Colors.transparent,
                                    ),
                                  ),
                                ];
                              },
                              body: Padding(
                                padding: EdgeInsets.only(top: 77),
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      if (!loading &&
                                          cityWeatherAl.length != 0) ...{
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 22),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: GestureDetector(
                                              onTap: () {
                                                showCupertinoModalPopup<void>(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 0,
                                                          vertical: 0),
                                                      child: Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.black,
                                                          borderRadius:
                                                              BorderRadius.only(
                                                                  topLeft: Radius
                                                                      .circular(
                                                                          16),
                                                                  topRight: Radius
                                                                      .circular(
                                                                          16)),
                                                        ),
                                                        height: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .height -
                                                            500,
                                                        child:
                                                            SingleChildScrollView(
                                                          child: Column(
                                                              children: [
                                                                Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  children: [
                                                                    Padding(
                                                                      padding: const EdgeInsets
                                                                          .only(
                                                                          top:
                                                                              9,
                                                                          bottom:
                                                                              4),
                                                                      child:
                                                                          DefaultTextStyle(
                                                                        style: TextStyle(
                                                                            color: Colors
                                                                                .white,
                                                                            fontSize:
                                                                                16,
                                                                            fontWeight:
                                                                                FontWeight.bold),
                                                                        child:
                                                                            Text(
                                                                          'Alerts +',
                                                                        ),
                                                                      ),
                                                                    )
                                                                  ],
                                                                ),
                                                                Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          8.0),
                                                                  child:
                                                                      Container(
                                                                          decoration:
                                                                              BoxDecoration(
                                                                            borderRadius:
                                                                                BorderRadius.all(Radius.circular(9)),
                                                                            color: Color.fromARGB(
                                                                                60,
                                                                                49,
                                                                                49,
                                                                                49),
                                                                          ),
                                                                          child:
                                                                              SingleChildScrollView(
                                                                            child:
                                                                                Column(
                                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                                              children: [
                                                                                Padding(
                                                                                  padding: const EdgeInsets.all(8.0),
                                                                                  child: DefaultTextStyle(
                                                                                    style: TextStyle(),
                                                                                    child: Text('Sender Name: ' + cityWeatherAl[0].sender_name),
                                                                                  ),
                                                                                ),
                                                                                SizedBox(
                                                                                  height: 5,
                                                                                ),
                                                                                Padding(
                                                                                  padding: const EdgeInsets.all(8.0),
                                                                                  child: DefaultTextStyle(
                                                                                    textAlign: TextAlign.start,
                                                                                    style: TextStyle(color: Colors.white, fontSize: 14),
                                                                                    child: Text(
                                                                                      'Description: ' + cityWeatherAl[0].description,
                                                                                    ),
                                                                                  ),
                                                                                )
                                                                              ],
                                                                            ),
                                                                          )),
                                                                )
                                                              ]),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                              child: Container(
                                                width: double.infinity,
                                                height: 110,
                                                child: Stack(
                                                  children: [
                                                    BackdropFilter(
                                                      filter: ImageFilter.blur(
                                                          sigmaX: 10,
                                                          sigmaY: 51),
                                                      child: Container(
                                                        height: 110,
                                                        padding:
                                                            EdgeInsets.all(5),
                                                        child: Column(
                                                          children: [
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(8.0),
                                                              child: Row(
                                                                children: [
                                                                  Icon(
                                                                    CupertinoIcons
                                                                        .alarm,
                                                                    size: 18,
                                                                    color: Colors
                                                                        .white54,
                                                                  ),
                                                                  Text(
                                                                    ' ALERTS',
                                                                    style: TextStyle(
                                                                        color: Colors
                                                                            .white54,
                                                                        fontWeight:
                                                                            FontWeight.w600),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            Divider(
                                                              height: 2,
                                                              color: Colors
                                                                  .white54,
                                                            ),
                                                            Flexible(
                                                              child: Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Padding(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            4.0),
                                                                    child: Text(
                                                                      cityWeatherAl[
                                                                              0]
                                                                          .sender_name,
                                                                      style: TextStyle(
                                                                          overflow: TextOverflow
                                                                              .ellipsis,
                                                                          color: Colors
                                                                              .white54,
                                                                          fontSize:
                                                                              12),
                                                                    ),
                                                                  ),
                                                                  Padding(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            4.0),
                                                                    child: Text(
                                                                      maxLines:
                                                                          1,
                                                                      cityWeatherAl[
                                                                              0]
                                                                          .description,
                                                                      style: TextStyle(
                                                                          overflow: TextOverflow
                                                                              .ellipsis,
                                                                          color: Colors
                                                                              .white70,
                                                                          fontSize:
                                                                              15),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      },
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            top: 5, right: 22, left: 22),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Container(
                                            width: double.infinity,
                                            height: 173,
                                            child: Stack(
                                              children: [
                                                BackdropFilter(
                                                  filter: ImageFilter.blur(
                                                      sigmaX: 10, sigmaY: 51),
                                                  child: Container(
                                                    height: 173,
                                                    padding: EdgeInsets.all(5),
                                                    child: Column(
                                                      children: [
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(8.0),
                                                          child: Row(
                                                            children: [
                                                              Icon(
                                                                CupertinoIcons
                                                                    .clock,
                                                                size: 18,
                                                                color: Colors
                                                                    .white54,
                                                              ),
                                                              Text(
                                                                ' 24-HOURS FORECAST',
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .white54,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        Divider(
                                                          height: 2,
                                                          color: Colors.white54,
                                                        ),
                                                        Flexible(
                                                          child:
                                                              ListView.builder(
                                                                  padding:
                                                                      EdgeInsets
                                                                          .zero,
                                                                  shrinkWrap:
                                                                      true,
                                                                  scrollDirection:
                                                                      Axis
                                                                          .horizontal,
                                                                  itemCount: cityWeatherHr
                                                                              .length >
                                                                          24
                                                                      ? 24
                                                                      : cityWeatherHr
                                                                          .length,
                                                                  itemBuilder:
                                                                      (context,
                                                                          index) {
                                                                    return Container(
                                                                      padding:
                                                                          EdgeInsets.all(
                                                                              22),
                                                                      child:
                                                                          Column(
                                                                        children: [
                                                                          Column(
                                                                            children: [
                                                                              Text(getTime(cityWeatherHr[index].dt), style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                                                                            ],
                                                                          ),
                                                                          Stack(
                                                                            alignment:
                                                                                AlignmentDirectional.bottomCenter,
                                                                            children: [
                                                                              Image(
                                                                                image: AssetImage("assets/icons/${cityWeatherHr[index].weather[0].icon}.png"),
                                                                                height: 29,
                                                                                width: 32,
                                                                              ),
                                                                            ],
                                                                          ),
                                                                          Text(
                                                                            cityWeatherHr[index].temp.toStringAsFixed(0) +
                                                                                '\u00B0',
                                                                            style: TextStyle(
                                                                                color: Colors.white,
                                                                                fontSize: 16,
                                                                                fontWeight: FontWeight.w600),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    );
                                                                  }),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 22, vertical: 6),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Container(
                                            height: 415,
                                            child: Stack(
                                              children: [
                                                BackdropFilter(
                                                  filter: ImageFilter.blur(
                                                      sigmaX: 10, sigmaY: 51),
                                                  child: Container(
                                                    height: 415,
                                                    padding: EdgeInsets.all(5),
                                                    child: Column(
                                                      children: [
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  top: 8.0,
                                                                  left: 8.0,
                                                                  right: 8.0,
                                                                  bottom: 8.0),
                                                          child: Row(
                                                            children: [
                                                              Icon(
                                                                CupertinoIcons
                                                                    .calendar,
                                                                size: 18,
                                                                color: Colors
                                                                    .white54,
                                                              ),
                                                              Text(
                                                                ' 8-DAY FORECAST',
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .white54,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        Divider(
                                                          height: 2,
                                                          color: Colors.white54,
                                                        ),
                                                        Flexible(
                                                          child: ListView
                                                              .separated(
                                                            physics:
                                                                NeverScrollableScrollPhysics(),
                                                            scrollDirection:
                                                                Axis.vertical,
                                                            shrinkWrap: true,
                                                            padding:
                                                                EdgeInsets.zero,
                                                            itemCount: cityWeatherDy
                                                                        .length >
                                                                    10
                                                                ? 10
                                                                : cityWeatherDy
                                                                    .length,
                                                            itemBuilder:
                                                                (context,
                                                                    index) {
                                                              return Column(
                                                                children: [
                                                                  Container(
                                                                    padding: EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            8,
                                                                        vertical:
                                                                            8),
                                                                    child: Row(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .spaceBetween,
                                                                      children: [
                                                                        SizedBox(
                                                                          width:
                                                                              80,
                                                                          child:
                                                                              Text(
                                                                            getDay(cityWeatherDy[index].dt),
                                                                            style: TextStyle(
                                                                                fontSize: 16,
                                                                                color: Colors.white,
                                                                                fontWeight: FontWeight.w700),
                                                                          ),
                                                                        ),
                                                                        Stack(
                                                                          alignment:
                                                                              AlignmentDirectional.bottomCenter,
                                                                          children: [
                                                                            Image(
                                                                              image: AssetImage("assets/icons/${cityWeatherHr[index].weather[0].icon}.png"),
                                                                              height: 30,
                                                                              width: 33,
                                                                            ),
                                                                          ],
                                                                        ),
                                                                        Text(
                                                                          cityWeatherDy[index].tempmax.toStringAsFixed(0) +
                                                                              '\u00B0 / ' +
                                                                              cityWeatherDy[index].tempmin.toStringAsFixed(0) +
                                                                              '\u00B0',
                                                                          style: TextStyle(
                                                                              fontSize: 15,
                                                                              color: Colors.white,
                                                                              fontWeight: FontWeight.w700),
                                                                        )
                                                                      ],
                                                                    ),
                                                                  )
                                                                ],
                                                              );
                                                            },
                                                            separatorBuilder:
                                                                (BuildContext
                                                                        context,
                                                                    int index) {
                                                              return Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .only(
                                                                        left:
                                                                            8.0,
                                                                        right:
                                                                            8.0),
                                                                child: Divider(
                                                                  height: 0,
                                                                  color: Colors
                                                                      .white54,
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 22, right: 6),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: Container(
                                                  width: double.infinity,
                                                  height: 180,
                                                  child: Stack(
                                                    children: [
                                                      BackdropFilter(
                                                        filter:
                                                            ImageFilter.blur(
                                                                sigmaX: 10,
                                                                sigmaY: 51),
                                                        child: Container(
                                                          height: 180,
                                                          padding:
                                                              EdgeInsets.all(5),
                                                          child: Column(
                                                            children: [
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(
                                                                        8.0),
                                                                child: Row(
                                                                  children: [
                                                                    Icon(
                                                                      CupertinoIcons
                                                                          .wind,
                                                                      size: 18,
                                                                      color: Colors
                                                                          .white54,
                                                                    ),
                                                                    Text(
                                                                      ' WIND',
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                              .white54,
                                                                          fontWeight:
                                                                              FontWeight.w600),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              Flexible(
                                                                child: Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          8.0),
                                                                  child: Stack(
                                                                    children: [
                                                                      Container(
                                                                        width:
                                                                            100, // Đặt kích thước vòng tròn
                                                                        height:
                                                                            100, // Đặt kích thước vòng tròn
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          shape:
                                                                              BoxShape.circle, // Đặt hình dạng hình tròn
                                                                          color:
                                                                              Colors.white10, // Đặt màu xám
                                                                        ),
                                                                        child:
                                                                            Center(
                                                                          child:
                                                                              Column(
                                                                            mainAxisAlignment:
                                                                                MainAxisAlignment.center,
                                                                            children: [
                                                                              Text(
                                                                                cityWeather[cityIndex].cityWspeed.toStringAsFixed(0),
                                                                                style: TextStyle(
                                                                                  color: Colors.white,
                                                                                  fontSize: 25,
                                                                                  fontWeight: FontWeight.w700,
                                                                                ),
                                                                              ),
                                                                              Text(
                                                                                'km/h',
                                                                                style: TextStyle(
                                                                                  color: Colors.white70,
                                                                                  fontSize: 14,
                                                                                  fontWeight: FontWeight.w700,
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Flexible(
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 6, right: 22),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: Container(
                                                  width: double.infinity,
                                                  height: 180,
                                                  child: Stack(
                                                    children: [
                                                      BackdropFilter(
                                                        filter:
                                                            ImageFilter.blur(
                                                                sigmaX: 10,
                                                                sigmaY: 51),
                                                        child: Container(
                                                          height: 180,
                                                          padding:
                                                              EdgeInsets.all(5),
                                                          child: Column(
                                                            children: [
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(
                                                                        8.0),
                                                                child: Row(
                                                                  children: [
                                                                    Icon(
                                                                      CupertinoIcons
                                                                          .eye_fill,
                                                                      size: 18,
                                                                      color: Colors
                                                                          .white54,
                                                                    ),
                                                                    Text(
                                                                      ' VISIBILITY',
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                              .white54,
                                                                          fontWeight:
                                                                              FontWeight.w600),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              Flexible(
                                                                child: Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          8.0),
                                                                  child: Stack(
                                                                    children: [
                                                                      Container(
                                                                        width:
                                                                            100, // Đặt kích thước vòng tròn
                                                                        height:
                                                                            100, // Đặt kích thước vòng tròn
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          shape:
                                                                              BoxShape.circle, // Đặt hình dạng hình tròn
                                                                          color:
                                                                              Colors.white12, // Đặt màu xám
                                                                        ),
                                                                        child:
                                                                            Center(
                                                                          child:
                                                                              Column(
                                                                            mainAxisAlignment:
                                                                                MainAxisAlignment.center,
                                                                            children: [
                                                                              Text(
                                                                                '${cityWeather[cityIndex].cityVisi.toStringAsFixed(0)}',
                                                                                style: TextStyle(
                                                                                  color: Colors.white,
                                                                                  fontSize: 30,
                                                                                  fontWeight: FontWeight.w700,
                                                                                ),
                                                                              ),
                                                                              Text(
                                                                                'km',
                                                                                style: TextStyle(
                                                                                  color: Colors.white70,
                                                                                  fontSize: 15,
                                                                                  fontWeight: FontWeight.w700,
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 22, right: 6, top: 5),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: Container(
                                                  width: double.infinity,
                                                  height: 180,
                                                  child: Stack(
                                                    children: [
                                                      BackdropFilter(
                                                        filter:
                                                            ImageFilter.blur(
                                                                sigmaX: 10,
                                                                sigmaY: 51),
                                                        child: Container(
                                                          height: 180,
                                                          padding:
                                                              EdgeInsets.all(5),
                                                          child: Column(
                                                            children: [
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(
                                                                        8.0),
                                                                child: Row(
                                                                  children: [
                                                                    Icon(
                                                                      CupertinoIcons
                                                                          .drop_fill,
                                                                      size: 18,
                                                                      color: Colors
                                                                          .white54,
                                                                    ),
                                                                    Text(
                                                                      ' HUMIDITY',
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                              .white54,
                                                                          fontWeight:
                                                                              FontWeight.w600),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              Flexible(
                                                                child: Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          8.0),
                                                                  child: Stack(
                                                                    children: [
                                                                      Container(
                                                                        width:
                                                                            100, // Đặt kích thước vòng tròn
                                                                        height:
                                                                            100, // Đặt kích thước vòng tròn
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          shape:
                                                                              BoxShape.circle, // Đặt hình dạng hình tròn
                                                                          color:
                                                                              Colors.white10, // Đặt màu xám
                                                                        ),
                                                                        child:
                                                                            Center(
                                                                          child:
                                                                              Column(
                                                                            mainAxisAlignment:
                                                                                MainAxisAlignment.center,
                                                                            children: [
                                                                              Text(
                                                                                '${cityWeather[cityIndex].cityhumidity}%',
                                                                                style: TextStyle(
                                                                                  color: Colors.white,
                                                                                  fontSize: 25,
                                                                                  fontWeight: FontWeight.w700,
                                                                                ),
                                                                              ),
                                                                              Text(
                                                                                'Humidity',
                                                                                style: TextStyle(
                                                                                  color: Colors.white70,
                                                                                  fontSize: 14,
                                                                                  fontWeight: FontWeight.w700,
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Flexible(
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 6, right: 22, top: 5),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: Container(
                                                  width: double.infinity,
                                                  height: 180,
                                                  child: Stack(
                                                    children: [
                                                      BackdropFilter(
                                                        filter:
                                                            ImageFilter.blur(
                                                                sigmaX: 10,
                                                                sigmaY: 51),
                                                        child: Container(
                                                          height: 180,
                                                          padding:
                                                              EdgeInsets.all(5),
                                                          child: Column(
                                                            children: [
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(
                                                                        8.0),
                                                                child: Row(
                                                                  children: [
                                                                    Icon(
                                                                      CupertinoIcons
                                                                          .sun_max_fill,
                                                                      size: 18,
                                                                      color: Colors
                                                                          .white54,
                                                                    ),
                                                                    Text(
                                                                      ' UV INDEX',
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                              .white54,
                                                                          fontWeight:
                                                                              FontWeight.w600),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              Flexible(
                                                                child: Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          8.0),
                                                                  child: Stack(
                                                                    children: [
                                                                      Container(
                                                                        width:
                                                                            100, // Đặt kích thước vòng tròn
                                                                        height:
                                                                            100, // Đặt kích thước vòng tròn
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          shape:
                                                                              BoxShape.circle, // Đặt hình dạng hình tròn
                                                                          color:
                                                                              Colors.white10, // Đặt màu xám
                                                                        ),
                                                                        child:
                                                                            Center(
                                                                          child:
                                                                              Column(
                                                                            mainAxisAlignment:
                                                                                MainAxisAlignment.center,
                                                                            children: [
                                                                              Text(
                                                                                '${loading ? 0 : cityWeatherCu[0].cityUiv}',
                                                                                style: TextStyle(
                                                                                  color: Colors.white,
                                                                                  fontSize: 25,
                                                                                  fontWeight: FontWeight.w700,
                                                                                ),
                                                                              ),
                                                                              Text(
                                                                                'UV',
                                                                                style: TextStyle(
                                                                                  color: Colors.white70,
                                                                                  fontSize: 14,
                                                                                  fontWeight: FontWeight.w700,
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              )));
                    }
                  }),
            ),
          ],
        ));
  }
}

class WindDirectionPainter extends CustomPainter {
  final double windDirection;

  WindDirectionPainter(this.windDirection);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    double arrowLength = size.height * 0.95;
    double arrowWidth = size.width * 0.07;
    double arrowHeadWidth = arrowWidth * 1;
    double arrowHeadLength = size.width * 0.15;

    Path path = Path();
    path.moveTo(-arrowLength / 2, 0);
    path.lineTo(arrowLength / 2 - arrowHeadLength, 0);
    path.lineTo(arrowLength / 2 - arrowHeadLength, -arrowHeadWidth / 2);
    path.lineTo(arrowLength / 2, 0);
    path.lineTo(arrowLength / 2 - arrowHeadLength, arrowHeadWidth / 2);
    path.lineTo(arrowLength / 2 - arrowHeadLength, 0);
    path.lineTo(-arrowLength / 2, 0);
    path.close();

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2 - 0.1);
    canvas.rotate(windDirection * (pi / 180));
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
